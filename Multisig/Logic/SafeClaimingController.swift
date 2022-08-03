//
//  SafeClaimingController.swift
//  Multisig
//
//  Created by Mouaz on 8/3/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import SwiftCryptoTokenFormatter

class SafeClaimingController {
    static let shared = SafeClaimingController()

    private init() {
        
    }

    func claimingAmountFor(safe: Address) -> SafeClaimingAmount? {
        guard !hasClaimed(safe: safe) else { return nil }

        return SafeClaimingAmount(ecosystemAmount: (now: BigDecimal(10012, 2), future: BigDecimal(5014, 2)),
                                  userAmount: (now: BigDecimal(12050, 2), future: BigDecimal(7067, 2)))
    }

    func claimFor(safe: Address) {
        claimedSafes.append(safe)
    }

    func hasClaimed(safe: Address) -> Bool {
        claimedSafes.contains(safe)
    }

    private var claimedSafes: [Address] = []
}

struct SafeClaimingAmount {
    let ecosystemAmount: (now: BigDecimal, future: BigDecimal)
    let userAmount: (now: BigDecimal, future: BigDecimal)

    var totalClaimable: BigDecimal {
        BigDecimal(ecosystemAmount.now.value + userAmount.now.value,
                   max(ecosystemAmount.now.precision, userAmount.now.precision))
    }

    var totalClaimableInFuture: BigDecimal {
        BigDecimal(ecosystemAmount.future.value + userAmount.future.value,
                   max(ecosystemAmount.future.precision, userAmount.future.precision))
    }
}
