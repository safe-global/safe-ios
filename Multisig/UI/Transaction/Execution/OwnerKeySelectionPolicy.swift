//
//  OwnerKeySelectionPolicy.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/*
 Owner Key Selection Policy

 Criteria to search for the default key - prefer the highest balance that is enough to pay for the transaction, and prefer owner keys
 Key is owner AND has enough balance AND is max amount
 If not, the key that has enough balance
 If not, the key that is owner and has highest balance
 If not, the key has highest balance
 [not possible now]: ~If not, the most recently used key (do we have this info?)~
 If not, the first key from existing ones
 The “Review” screen requires at least one key to be in the app in order for the execution to work, therefore there will always be a key to select from.
 Changing the selected key can affect the gas estimation, so when the key changes, the gas estimation policy must be notified about this.
 */
import Solidity

class OwnerKeySelectionPolicy {

    struct KeyCandidate: Equatable {
        var key: KeyInfo
        var balance: Sol.UInt256 = 0
        var isOwner: Bool = false
    }

    /// Searches for the default key matching required amount on their balance.
    /// - Parameters:
    ///   - keys: list of keys with balances and owner status. If balance is unknown, it should be set to 0.
    ///   - requiredAmount: if the required balance is known, it should be passed. Default is 0.
    /// - Returns:
    ///     - Prefers owner to non-owners with enough balance
    ///     - Prefers higher-balance keys
    ///     - If none of the keys have enough balance or required amount is not specified, prefers owner key with the highest balance
    func defaultExecutionKey(in candidates: [KeyCandidate], requiredAmount: Sol.UInt256 = 0) -> KeyCandidate? {
        if candidates.isEmpty {
            return nil
        }

        if candidates.count == 1 {
            return candidates.first
        }

        let byBalanceDescending = { (lhs: KeyCandidate, rhs: KeyCandidate) -> Bool in
            lhs.balance > rhs.balance
        }
        let sortedOwners = candidates.filter { $0.isOwner }.sorted(by: byBalanceDescending)

        if let firstOwner = sortedOwners.first, firstOwner.balance >= requiredAmount {
            return firstOwner
        }

        // now we know that owners don't have enough balance.

        let sortedNonOwners = candidates.filter { !$0.isOwner }.sorted(by: byBalanceDescending)

        if let firstNonOwner = sortedNonOwners.first, firstNonOwner.balance >= requiredAmount {
            return firstNonOwner
        }

        // now we know that non-owners also don't have enough balance.
        // return any owner or non-owner with the highest balance.
        let result = sortedOwners.first ?? sortedNonOwners.first
        return result
    }
}
