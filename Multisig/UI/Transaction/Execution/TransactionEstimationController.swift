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

    let transaction: EthTransaction
    let chain: Chain
    let rpcClient: JsonRpc2.Client

    init(transaction: EthTransaction, chain: Chain) {
        self.transaction = transaction
        self.chain = chain
        self.rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: chain.authenticatedRpcUrl.absoluteString), serializer: JsonRpc2.DefaultSerializer())
    }

    // main function
    func estimate(completion: @escaping (Result<EthTransaction, Error>) -> Void) -> URLSessionTask? {
        var tx = transaction
        let task = estimateTransactionWithRpc(tx: tx) { estimationResult in
            let result = estimationResult.map { (gas: Sol.UInt64, transactionCount: Sol.UInt64, gasPrice: Sol.UInt256) -> EthTransaction in
                tx.update(gas: gas,
                          transactionCount: transactionCount,
                          baseFee: gasPrice)
                return tx
            }
            completion(result)
        }
        return task
    }

    // TODO: estimate gas price using the chain config (oracles, or fixed price)

    // on completion:

    // estimates with the data in the 'pending' block
    // tx.from must not be nil or it will crash
    // completion may be called on background thread
    func estimateTransactionWithRpc(tx: EthTransaction, completion: @escaping (Result<(gas: Sol.UInt64, transactionCount: Sol.UInt64, gasPrice: Sol.UInt256), Error>) -> Void) -> URLSessionTask? {
        assert(transaction.from != nil, "From must be set for estimation")

        let getEstimate = EthRpc1.eth_estimateGas(tx)
        let getTransactionCount = EthRpc1.eth_getTransactionCount(address: EthRpc1.Data(tx.from!), block: .tag(.pending))
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
            completion(.failure(error))
            return nil
        }

        let task = rpcClient.send(request: batch) { batchResponse in
            guard let batchResponse = batchResponse else {
                // no response is a failed batch request
                completion(.failure(TransactionEstimationError(code: -1, message: "Server did not respond")))
                return
            }

            switch batchResponse {
            case .response(let response):
                // single response is a failed batch request
                if let error = response.error {
                    completion(.failure(error))
                } else {
                    completion(.failure(TransactionEstimationError(code: -2, message: "Failed to estimate transaction.")))
                }

            case .array(let responses):
                // at this point it is guaranteed that there's a response object for each request.

                // reason for failing on any error is to make this estimation implementation simpler
                let allErrors = responses.compactMap(\.error)
                if let error = allErrors.first {
                    completion(.failure(error))
                    return
                }

                // if there are no errors, then it is guaranteed that responses have results.
                let gasEstimateResult = responses.first(where: { $0.id == getEstimateRequest.id })!.result!
                let transactionCountResult = responses.first(where: { $0.id == getTransactionCountRequest.id })!.result!
                let priceResult = responses.first(where: { $0.id == getPriceRequest.id })!.result!


                do {
                    // converting from json values to the API types
                    let gasEstimate: EthRpc1.Quantity<Sol.UInt64> = try getEstimate.result(from: gasEstimateResult)
                    let transactionCount: EthRpc1.Quantity<Sol.UInt64> = try getTransactionCount.result(from: transactionCountResult)
                    let baseFee: EthRpc1.Quantity<Sol.UInt256> = try getPrice.result(from: priceResult)

                    completion(.success((gas: gasEstimate.storage, transactionCount: transactionCount.storage, gasPrice: baseFee.storage)))
                } catch {
                    completion(.failure(error))
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
