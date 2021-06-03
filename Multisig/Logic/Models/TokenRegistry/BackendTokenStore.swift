//
//  BackendTokenStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct BackendTokenStore {

    static func logo(_ address: Address) -> URL? {
        URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.checksummed).png")
    }

    func tokens() -> [Token] {
        do {
            let tokens = try App.shared.safeTransactionService.tokens().results
            return tokens.map { Token($0) }
        } catch {
            return []
        }
    }

    func token(address: Address) -> Token? {
        do {
            let result = try App.shared.safeTransactionService.token(address)
            return Token(result)
        } catch {
            // not found on in backend or some other error
            return nil
        }
    }

    func add(_ token: Token) {
        // no-op
    }

}
