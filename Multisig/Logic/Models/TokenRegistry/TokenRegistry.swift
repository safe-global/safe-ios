//
//  TokenRegistry.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TokenRegistry {

    private var hardcoded = HardcodedTokenStore()
    private var cache = InMemoryTokenStore()
    private var backend = BackendTokenStore()
    private var blockchain = BlockchainTokenStore()

    // added for thread safety
    private var queue = DispatchQueue(label: "SerialTokenRegistry")

    func load(completion: @escaping () -> Void = {}) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.async { [unowned self] in
            let tokens = self.backend.tokens()
            tokens.forEach { self.cache.add($0) }
            completion()
        }
    }

    func token(address: Address) -> Token? {
        dispatchPrecondition(condition: .notOnQueue(queue))

        var result: Token?
        queue.sync { [unowned self] in
            if let token = self.hardcoded.token(address: address) {
                result = token
            } else if let token = self.cache.token(address: address) {
                result = token
            } else if let token = self.backend.token(address: address) {
                self.cache.add(token)
                result = token
            } else if let token = self.blockchain.token(address: address) {
                self.cache.add(token)
                result = token
            } else {
                result = nil
            }
        }
        return result
    }

    subscript(address: Address) -> Token? {
        token(address: address)
    }

    subscript(address: String) -> Token? {
        guard let address = Address(address) else { return nil }
        return self[address]
    }

    func update(token: Token) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync { [unowned self] in
            self.cache.add(token)
        }
    }

}
