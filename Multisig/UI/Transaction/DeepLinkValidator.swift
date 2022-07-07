//
//  TransactionRequestValidator.swift
//  Multisig
//
//  Created by Moaaz on 7/6/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct DeepLinkValidator {
    private static let pattern = "^https://gnosis-safe.io/app/([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})/([-a-zA-Z0-9])/([-a-zA-Z0-9])"

    static func isValid(url: URL) -> Bool {
        guard url.absoluteString.matches(pattern: pattern) else { return false }

        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }

        guard
            matches.count >= 3 &&
            // safe address at position 1
            Address(matches[1]) != nil
        else {
            return false
        }
        return true
    }

//    static func parameters(from url: URL) -> TransactionRequestParameters? {
//        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }
//        guard
//            matches.count == 3,
//            let chain = Chain.by(shortName: matches[0]),
//            let safe = Address(matches[1]),
//            let owner = Address(matches[2])
//        else {
//            return nil
//        }
//        return TransactionRequestParameters(
//            chain: chain,
//            safeAddress: safe,
//            ownerAddress: owner
//        )
//    }
}
