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

class TransactionEstimationController {

    let rpcClient: JsonRpc2.Client

    init(rpcUri: String) {
        self.rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: rpcUri), serializer: JsonRpc2.DefaultSerializer())
    }

    typealias EstimateCompletion = (Result<(gas: Result<Sol.UInt64, Error>, transactionCount: Result<Sol.UInt64, Error>, gasPrice: Result<Sol.UInt256, Error>), Error>) -> Void

    func estimateTransactionWithRpc(tx: EthTransaction, completion: @escaping EstimateCompletion) -> URLSessionTask? {
        // remove the fee because we want to estimate it.
        var tx = tx
        tx.removeFee()
        let getEstimate = EthRpc1.eth_estimateGas(tx)

        let getTransactionCount = EthRpc1.eth_getTransactionCount(address: EthRpc1.Data(tx.from ?? .init()), block: .tag(.pending))

        let getPrice = EthRpc1.eth_gasPrice()

        let batch: JsonRpc2.BatchRequest
        let getEstimateRequest: JsonRpc2.Request
        let getTransactionCountRequest: JsonRpc2.Request
        let getPriceRequest: JsonRpc2.Request


        do {
            getEstimateRequest = try getEstimate.request(id: .int(1))
            getTransactionCountRequest = try getTransactionCount.request(id: .int(2))
            getPriceRequest = try getPrice.request(id: .int(3))

            batch = try JsonRpc2.BatchRequest(requests: [
                getEstimateRequest, getTransactionCountRequest, getPriceRequest
            ])
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let task = rpcClient.send(request: batch) { batchResponse in
            guard let batchResponse = batchResponse else {
                // no response is a failed batch request
                dispatchOnMainThread(completion(.failure(TransactionEstimationError(code: -1, message: "Server did not respond"))))
                return
            }

            switch batchResponse {
            case .response(let response):
                // single response is a failed batch request
                if let error = response.error {
                    dispatchOnMainThread(completion(.failure(error)))
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
                let gasResult = result(request: getEstimateRequest, method: getEstimate, responses: responses).map(\.storage)
                let txCountResult = result(request: getTransactionCountRequest, method: getTransactionCount, responses: responses).map(\.storage)
                let priceResult = result(request: getPriceRequest, method: getPrice, responses: responses).map(\.storage)

                dispatchOnMainThread(completion(.success((gasResult, txCountResult, priceResult))))
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
