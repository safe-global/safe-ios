//
//  TransactionEstimationController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Ethereum
import JsonRpc2
import Solidity
import Json
import SafeAbi

class TransactionEstimationController {

    let legacyEstimateGasChainIds = [
        // xDai
        "100",
        // Energey Web Chain
        "246",
        // Volta
        "73799",
        // arbitrm one
        "42161",
        // binance smart chain
        "56",
        // optimism
        "10",
        // aurora
        "1313161554",
        // Polygon
        "137"
    ]

    let rpcClient: JsonRpc2.Client
    let chain: Chain

    init(rpcUri: String, chain: Chain) {
        self.chain = chain
        self.rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: rpcUri), serializer: JsonRpc2.DefaultSerializer())
    }

    typealias EstimateCompletion = (Result<(gas: Result<Sol.UInt64, Error>, transactionCount: Result<Sol.UInt64, Error>, gasPrice: Result<Sol.UInt256, Error>, ethCall: Result<Data, Error>, balance: Result<Sol.UInt256, Error>), Error>) -> Void

    func estimateTransactionWithRpc(tx: EthTransaction, block: EthRpc1.BlockSpecifier = .tag(.pending), completion: @escaping EstimateCompletion) -> URLSessionTask? {
        // check if we have hint from the chain configuration about the gas price. For now support only fixed.
        // find the first 'fixed' gas price
        var fixedGasPrice: Sol.UInt256? = nil

        for case SCGModels.GasPrice.fixed(let fixed) in chain.gasPrice where Sol.UInt256(fixed.weiValue) != nil {
            fixedGasPrice = Sol.UInt256(fixed.weiValue)!
            break
        }

        var block: EthRpc1.BlockSpecifier = block

        if chain.id == "137" {
            // Polygon has only "latest" block parameter
            // see: https://docs.polygon.technology/docs/edge/get-started/json-rpc-commands/#eth_call
            block = .tag(.latest)
        }

        // remove the fee because we want to estimate it.
        var tx = tx
        tx.removeFee()

        let getEstimateNew = EthRpc1.eth_estimateGas(tx)
        let getEstimateLegacy = EthRpc1.eth_estimateGasLegacyApi(tx)

        let usingLegacyGasApi = chain.id != nil && legacyEstimateGasChainIds.contains(chain.id!)

        let getTransactionCount = EthRpc1.eth_getTransactionCount(address: EthRpc1.Data(tx.from ?? .init()), block: block)

        let getPrice = EthRpc1.eth_gasPrice()

        let ethCallNew = EthRpc1.eth_call(transaction: EthRpc1.Transaction(tx), block: block)
        let ethCallLegacy = EthRpc1.eth_callLegacyApi(transaction: EthRpc1.EstimateGasLegacyTransaction(tx), block: block)

        let getBalance = EthRpc1.eth_getBalance(address: EthRpc1.Data(tx.from ?? .init()), block: block)

        let batch: JsonRpc2.BatchRequest
        let getEstimateRequest: JsonRpc2.Request
        let getTransactionCountRequest: JsonRpc2.Request
        let getPriceRequest: JsonRpc2.Request
        let ethCallRequest: JsonRpc2.Request
        let getBalanceRequest: JsonRpc2.Request


        do {
            getEstimateRequest = try usingLegacyGasApi ? getEstimateLegacy.request(id: .int(1)) : getEstimateNew.request(id: .int(1))
            getTransactionCountRequest = try getTransactionCount.request(id: .int(2))
            getPriceRequest = try getPrice.request(id: .int(3))
            ethCallRequest = try usingLegacyGasApi ? ethCallLegacy.request(id: .int(4)) : ethCallNew.request(id: .int(4))
            getBalanceRequest = try getBalance.request(id: .int(5))

            batch = try JsonRpc2.BatchRequest(requests: [
                getEstimateRequest, getTransactionCountRequest, getPriceRequest, ethCallRequest, getBalanceRequest
            ])
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let task = rpcClient.send(request: batch) { [weak self] batchResponse in
            guard let self = self else { return }
            guard let batchResponse = batchResponse else {
                // no response is a failed batch request
                dispatchOnMainThread(completion(.failure(TransactionEstimationError(code: -1, message: "Server did not respond"))))
                return
            }

            switch batchResponse {
            case .response(let response):
                // single response is a failed batch request
                if let error = response.error {
                    let jsonError = (try? error.data?.convert(to: Json.NSError.self))?.nsError() ?? (error as NSError)
                    dispatchOnMainThread(completion(.failure(jsonError)))
                } else {
                    dispatchOnMainThread(completion(.failure(TransactionEstimationError(code: -2, message: "Failed to estimate transaction."))))
                }

            case .array(let responses):
                // at this point it is guaranteed that there's a response object for each request.
                // we get the result or error for each request
                func result<T: JsonRpc2Method>(request: JsonRpc2.Request, method: T, responses: [JsonRpc2.Response]) -> Result<T.Return, Error> where T.Return: Decodable {
                    let id = request.id
                    let resp = responses.first { $0.id == id }!
                    if let error = resp.error {
                        return .failure(error)
                    }
                    let json = resp.result!
                    do {
                        let result = try method.result(from: json)
                        return .success(result)
                    } catch {
                        return .failure(error)
                    }
                }
                let gasResult = usingLegacyGasApi ?
                    result(request: getEstimateRequest, method: getEstimateLegacy, responses: responses).map(\.storage)
                    : result(request: getEstimateRequest, method: getEstimateNew, responses: responses).map(\.storage)
                let txCountResult = result(request: getTransactionCountRequest, method: getTransactionCount, responses: responses).map(\.storage)
                let priceResult = fixedGasPrice.map { .success($0) } ?? result(request: getPriceRequest, method: getPrice, responses: responses).map(\.storage)
                let callResult = usingLegacyGasApi ?
                    result(request: ethCallRequest, method: ethCallLegacy, responses: responses).map(\.storage)
                    : result(request: ethCallRequest, method: ethCallNew, responses: responses).map(\.storage)
                let getBalanceResult = result(request: getBalanceRequest, method: getBalance, responses: responses).map(\.storage)


                dispatchOnMainThread(completion(.success((gasResult, txCountResult, priceResult, callResult, getBalanceResult))))

                // workaround for the 'Aurora' network: in the batch request it returns 0 gas price.
                if fixedGasPrice == nil, case Result<Sol.UInt256, Error>.success(let price) = priceResult, price == 0 {
                    // get gas price with a single request.
                    if let priceRequest = (try? EthRpc1.eth_gasPrice().request(id: .int(1))) {
                        self.rpcClient.send(request: priceRequest) { response in

                            guard let response = response else {
                                dispatchOnMainThread(completion(.success((gasResult, txCountResult, priceResult, callResult, getBalanceResult))))
                                return
                            }

                            let gasPriceResult = result(request: priceRequest, method: EthRpc1.eth_gasPrice(), responses: [response]).map(\.storage)

                            dispatchOnMainThread(completion(.success((gasResult, txCountResult, gasPriceResult, callResult, getBalanceResult))))

                        }
                    } else {
                        dispatchOnMainThread(completion(.success((gasResult, txCountResult, priceResult, callResult, getBalanceResult))))
                    }
                } else {
                    dispatchOnMainThread(completion(.success((gasResult, txCountResult, priceResult, callResult, getBalanceResult))))
                }
            }
        }
        return task
    }

}

struct TransactionEstimationError: LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String? {
        "\(message) (Error \(code))"
    }
}
