//
//  Allocation.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Allocation: Codable {
    var account: AddressString
    var chainId: Int
    var contract: AddressString
    var vestingId: DataString
    var durationWeeks: Int
    var startDate: UInt64
    var amount: UInt256String
    var curve: Int
    var proof: [DataString]?
    var tag: String
}
