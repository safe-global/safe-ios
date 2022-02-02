//
//  TransactionSender.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Ethereum
import JsonRpc2

class TransactionSender {

    let rpcClient: JsonRpc2.Client

    init(chain: Chain) {
        let rpcUri = chain.authenticatedRpcUrl.absoluteString
        self.rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: rpcUri), serializer: JsonRpc2.DefaultSerializer())
    }

    func send(tx: EthTransaction, completion: @escaping (Result<Eth.Hash, Error>) -> Void) -> URLSessionTask? {
        let rawTransaction = tx.rawTransaction()

        let sendRawTxMethod = EthRpc1.eth_sendRawTransaction(transaction: rawTransaction)

        let request: JsonRpc2.Request

        do {
            request = try sendRawTxMethod.request(id: .int(1))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let task = rpcClient.send(request: request) { response in
            guard let response = response else {
                let error = TransactionExecutionError(code: -4, message: "No response from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            if let error = response.error {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            guard let result = response.result else {
                let error = TransactionExecutionError(code: -5, message: "No result from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            let txHash: EthRpc1.Data
            do {
                txHash = try sendRawTxMethod.result(from: result)
            } catch {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            let hash = Eth.Hash(txHash.storage)
            dispatchOnMainThread(completion(.success(hash)))
        }

        return task
    }
}
