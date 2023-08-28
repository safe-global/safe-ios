//
//  RpcClient.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import JsonRpc2
import Json
import Ethereum

class RpcClient {
    var chain: Chain
    var rpcClient: JsonRpc2.Client

    init(chain: Chain) {
        self.chain = chain
        rpcClient = JsonRpc2.Client(
            transport: JsonRpc2.ClientHTTPTransport(url: chain.authenticatedRpcUrl.absoluteString),
            serializer: JsonRpc2.DefaultSerializer())
    }

    func eth_call<T>(to: Sol.Address, input: T, completion: @escaping (Result<T.Returns, Error>) -> Void) -> URLSessionTask? where T: SolContractFunction {
        let tx: EthTransaction = Eth.TransactionEip1559(
            to: to,
            data: Sol.Bytes(storage: input.encode())
        )
        // latest is the default for web3 js lib
        let block: EthRpc1.BlockSpecifier = .tag(.latest)

        let ethCall = EthRpc1.eth_callLegacyApi(transaction: EthRpc1.EstimateGasLegacyTransaction(tx), block: block)

        let request: JsonRpc2.Request
        do {
            request = try ethCall.request(id: .int(0))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        return send(request: request) { result in
            let callResult = result.flatMap { jsonElement -> Result<T.Returns, Error> in
                do {
                    let contractResponse = try ethCall.result(from: jsonElement).storage
                    let returns = try T.Returns.init(contractResponse)
                    return .success(returns)
                } catch {
                    return .failure(error)
                }

            }
            completion(callResult)
        }
    }

    func send(request: JsonRpc2.Request, completion: @escaping (Result<Json.Element, Error>) -> Void) -> URLSessionTask? {
        let task = rpcClient.send(request: request) { response in
            guard let response = response else {
                dispatchOnMainThread(completion(.failure("No response")))
                return
            }

            if let error = response.error {
                let jsonError = (try? error.data?.convert(to: Json.NSError.self))?.nsError() ?? (error as NSError)
                dispatchOnMainThread(completion(.failure(jsonError)))
                return
            }

            guard let result = response.result else {
                dispatchOnMainThread(completion(.failure("No result")))
                return
            }

            dispatchOnMainThread(completion(.success(result)))
        }

        return task
    }
}
