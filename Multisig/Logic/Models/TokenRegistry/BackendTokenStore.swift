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
        (try? App.shared.safeTransactionService.tokens().results.map { Token($0) }) ?? []
    }

    func token(address: Address) -> Token? {
        (try? App.shared.safeTransactionService.token(address)).map { Token($0) }
    }

    func add(_ token: Token) {
        // no-op
    }

}
