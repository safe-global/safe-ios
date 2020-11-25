//
//  ConfirmationRequestNotification.swift
//  NotificationServiceExtension
//
//  Created by Andrey Scherbovich on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct ConfirmationRequestNotification: MultisigNotification {
    let address: PlainAddress

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .confirmationRequest,
            let address = PlainAddress(payload.address)
        else {
            return nil
        }
        self.address = address
    }

    var localizedTitle: String {
        "Confirmation required"
    }

    var localizedBody: String {
        "\(address.truncatedInMiddle): A transaction requires your confirmation!"
    }
}
