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
        guard !hasClaimed(safe: safe) && safe != Address(exactly: "0xfF501B324DC6d78dC9F983f140B9211c3EdB4dc7") else { return nil }

        return SafeClaimingAmount(ecosystemAmount: (now: BigDecimal(0, 2), future: BigDecimal(0, 2)),
                                  userAmount: (now: BigDecimal(12050, 2), future: BigDecimal(12050, 2)))
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
