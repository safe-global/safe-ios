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

    // main function, the estimated transaction 
    func estimate(transaction: EthTransaction, completion: @escaping (Result<EthTransaction, Error>) -> Void) -> URLSessionTask? {
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

    func estimateTransactionWithRpc(tx: EthTransaction, completion: @escaping (Result<(gas: Sol.UInt64, transactionCount: Sol.UInt64, gasPrice: Sol.UInt256), Error>) -> Void) -> URLSessionTask? {
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

                // reason for failing on any error is to make this estimation implementation simpler
                let allErrors = responses.compactMap(\.error)
                if let error = allErrors.first {
                    dispatchOnMainThread(completion(.failure(error)))
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

                    dispatchOnMainThread(completion(.success((gas: gasEstimate.storage, transactionCount: transactionCount.storage, gasPrice: baseFee.storage))))
                } catch {
                    dispatchOnMainThread(completion(.failure(error)))
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
