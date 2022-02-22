//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity
import JsonRpc2

extension Node {
    public class Account {
        public var address: Sol.Address
        public var balance: Sol.UInt256? = nil
        public var nonce: Sol.UInt64? = nil
        public var code: Data? = nil

        public init(address: Sol.Address, balance: Sol.UInt256? = nil, nonce: Sol.UInt64? = nil, code: Data? = nil) {
            self.address = address
            self.balance = balance
            self.nonce = nonce
            self.code = code
        }
    }

    public static func account(at
            address: Sol.Address,
            block: NodeBlockId = .blockTag(.pending),
            using client: JsonRpc2.Client,
            completion: @escaping (Account) -> Void
    ) -> URLSessionTask? {
        let account = Account(address: address)
        let methodCalls: [JsonRpc2MethodCall] = [
            eth_getBalance(address: address, block: block) { result in
                account.balance = try? result.get()
            },
            eth_getTransactionCount(address: address, block: block) { result in
                account.nonce = try? result.get()
            },
            eth_getCode(address: address, block: block) { result in
                account.code = try? result.get()
            }
        ]
        let task = client.call(methodCalls) {
            completion(account)
        }
        return task
    }
}