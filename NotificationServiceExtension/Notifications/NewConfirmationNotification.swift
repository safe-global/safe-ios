//
//  NewConfirmationNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 07.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct NewConfirmationNotification: MultisigNotification {
    let address: PlainAddress
    let owner: PlainAddress

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .newConfirmation,
            let address = PlainAddress(payload.address),
            let owner = PlainAddress(payload.owner)
        else {
            return nil
        }
        self.address = address
        self.owner = owner
    }

    var localizedTitle: String {
        "Transaction confirmed"
    }

    var localizedBody: String {
        "\(address.truncatedInMiddle): Owner \(owner.truncatedInMiddle) confirmed transaction"
    }
}
