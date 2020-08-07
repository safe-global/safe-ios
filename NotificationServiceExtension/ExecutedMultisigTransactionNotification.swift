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

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .executedMultisigTx,
            let address = PlainAddress(payload.address)
        else {
            return nil
        }
        self.address = address
    }

    var localizedMessage: String {
        "\(address.truncatedInMiddle): Transaction executed"
    }
}
