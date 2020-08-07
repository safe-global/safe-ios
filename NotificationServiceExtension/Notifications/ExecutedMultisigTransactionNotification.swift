//
//  ExecutedMultisigTransactionNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ExecutedMultisigTransactionNotification: MultisigNotification {
    let address: PlainAddress
    let failed: Bool

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .executedMultisigTx,
            let address = PlainAddress(payload.address),
            let failed = payload.failed
        else {
            return nil
        }
        self.address = address
        self.failed = failed == "true"
    }

    var status: String {
        failed ? "failed" : "successful"
    }

    var localizedTitle: String {
        "Transaction \(status)"
    }

    var localizedBody: String {
        "\(address.truncatedInMiddle): Transaction \(status)"
    }
}
