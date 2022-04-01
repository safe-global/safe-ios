//
//  DefaultAccountBalanceLoader.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Ethereum
import Json
import JsonRpc2
import Solidity
import SwiftCryptoTokenFormatter

class DefaultAccountBalanceLoader: AccountBalanceLoader {

    let chain: Chain
    let client: JsonRpc2.Client
    var requiredBalance: Sol.UInt256 = 0

    init(chain: Chain) {
        self.chain = chain
        assert(chain.nativeCurrency != nil)
        client = JsonRpc2.Client(
            transport: JsonRpc2.ClientHTTPTransport(url: chain.authenticatedRpcUrl.absoluteString),
            serializer: JsonRpc2.DefaultSerializer())
    }
    /// will call completion handler on the main thread.
    ///
    /// resulting balances list must have the same count as the keys.
    ///
    /// The returned task is already resumed.
    func loadBalances(for keys: [KeyInfo], completion: @escaping (Result<[AccountBalanceUIModel], Error>) -> Void) -> URLSessionTask? {
        guard !keys.isEmpty else {
            dispatchOnMainThread(completion(.success([])))
            return nil
        }

        let nativeCoinSymbol = chain.nativeCurrency!.symbol ?? ""
        let nativeCoinDecimals = chain.nativeCurrency!.decimals
        let requiredBalance = self.requiredBalance

        let methods =  keys.map { keyInfo -> EthRpc1.eth_getBalance in
            let address: EthRpc1.Data = EthRpc1.Data(storage: keyInfo.address.data)
            let method = EthRpc1.eth_getBalance(
                address: address,
                block: .tag(.pending)
            )
            return method
        }

        // build batch account balance request
        let batch: JsonRpc2.BatchRequest
        let requests: [JsonRpc2.Request]
        do {
            requests = try methods.enumerated().map { index, method -> JsonRpc2.Request in
                let request = try method.request(id: .int(index))
                return request
            }
            batch = try JsonRpc2.BatchRequest(requests: requests)
        } catch {
            let gsError = GSError.error(description: "Failed to load balances due to internal error", error: error)
            dispatchOnMainThread(completion(.failure(gsError)))
            return nil
        }

        // send request
        return client.send(request: batch) { responseOrNil in
            let serverErrorMessage = "Failed to load balances due to server error"
            switch responseOrNil {
            case .none:
                // we expect to have response because all of the requests are not notifications (have id)
                let error = NSError(domain: "DefaultBalanceLoader", code: 0, userInfo: [:])
                let gsError = GSError.error(description: serverErrorMessage, error: error)
                dispatchOnMainThread(completion(.failure(gsError)))

            case .response(let response):
                let jsonError = (try? response.error?.data?.convert(to: Json.NSError.self))?.nsError() ?? (response.error as NSError?)
                let gsError = GSError.error(description: serverErrorMessage, error: jsonError)
                dispatchOnMainThread(completion(.failure(gsError)))

            case .array(let responses):
                // at this point there exists a response for each sent request.
                // the responses might be in different order
                // there should be the same number of responses.
                guard responses.count == requests.count else {
                    let gsError = GSError.error(description: serverErrorMessage)
                    dispatchOnMainThread(completion(.failure(gsError)))
                    return
                }

                let sorted = responses.sorted { lhs, rhs in lhs.id < rhs.id }
                let balances: [AccountBalanceUIModel] = zip(methods, sorted)
                    .map { method, response -> AccountBalanceUIModel in

                        // get the balance
                        let balance: Sol.UInt256?

                        if let result = response.result {
                            do {
                                balance = try method.result(from: result).storage
                            } catch {
                                balance = nil
                                LogService.shared.error("Failed to decode balance: \(error)")
                            }
                        } else {
                            balance = nil
                        }

                        // format to string
                        var model = AccountBalanceUIModel(displayAmount: "", isEnabled: true, amount: balance)

                        if let balance = balance {
                            let decimalAmount = BigDecimal(Int256(balance.big()), Int(nativeCoinDecimals))
                            let value = TokenFormatter().string(
                                from: decimalAmount,
                                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                                forcePlusSign: false
                            )

                            model.displayAmount = "\(value) \(nativeCoinSymbol)"
                            model.isEnabled = balance >= requiredBalance
                        }

                        return model
                }

                dispatchOnMainThread(completion(.success(balances)))
            }
        }
    }
}

func dispatchOnMainThread(_ closure: @autoclosure @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async(execute: closure)
    }
}
