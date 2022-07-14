//
//  AddOwnerRequestUrlValidator.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AddOwnerRequestParameters {
    var chain: Chain
    var safeAddress: Address
    var ownerAddress: Address
}

struct AddOwnerRequestValidator {
    private static let pattern = "^\(App.configuration.services.webAppURL)app/([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})/addOwner\\?address=(0x[a-fA-F0-9]{40})$"

    static func isValid(url: URL) -> Bool {
        guard url.absoluteString.matches(pattern: pattern) else { return false }

        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }

        guard
            matches.count == 3 &&
            // safe address at position 1
            Address(matches[1]) != nil &&
            // owner address at position 2
            Address(matches[2]) != nil
        else {
            return false
        }
        return true
    }

    static func parameters(from url: URL) -> AddOwnerRequestParameters? {
        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }
        guard
            matches.count == 3,
            let chain = Chain.by(shortName: matches[0]),
            let safe = Address(matches[1]),
            let owner = Address(matches[2])
        else {
            return nil
        }
        return AddOwnerRequestParameters(
            chain: chain,
            safeAddress: safe,
            ownerAddress: owner
        )
    }
}
