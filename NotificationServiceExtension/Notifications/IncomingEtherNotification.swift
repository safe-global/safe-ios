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

// *nativeCoin*
struct IncomingEtherNotification: MultisigNotification {
    let address: PlainAddress
    let value: BigInt

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .incomingEther,
            let address = PlainAddress(payload.address),
            let rawValue = payload.value,
            let value = BigInt(rawValue)
        else {
            return nil
        }
        self.address = address
        self.value = value
    }

    var localizedTitle: String {
        // *nativeCoin*
        "Incoming ETH"
    }

    var localizedBody: String {
        let safe = address.truncatedInMiddle
        let formatter = TokenFormatter()
        // *nativeCoin*
        let etherPrecision = 18
        let amount = formatter.string(
            // *nativeCoin*
            from: BigDecimal(value, etherPrecision),
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",")
        // *nativeCoin*
        return "\(safe): \(amount) ETH received"
    }
}
