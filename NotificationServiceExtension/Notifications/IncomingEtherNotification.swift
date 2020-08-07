//
//  IncomingEtherNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftCryptoTokenFormatter
import BigInt

struct IncomingEtherNotification: MultisigNotification {
    let address: PlainAddress
    let txHash: String
    let value: BigInt

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .incomingEther,
            let address = PlainAddress(payload.address),
            let txHash = payload.txHash,
            let rawValue = payload.value,
            let value = BigInt(rawValue)
        else {
            return nil
        }
        self.address = address
        self.txHash = txHash
        self.value = value
    }

    var localizedTitle: String {
        "Incoming ETH"
    }

    var localizedBody: String {
        let safe = address.truncatedInMiddle
        let formatter = TokenFormatter()
        let etherPrecision = 18
        let amount = formatter.string(
            from: BigDecimal(value, etherPrecision),
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")
        return "\(safe): \(amount) ETH received"
    }
}
