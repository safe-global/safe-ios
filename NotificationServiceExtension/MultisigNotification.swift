//
//  MultisigNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum NotificationType: String {
    case incomingEther = "INCOMING_ETHER"
    case incomingToken = "INCOMING_TOKEN"
    case executedMultisigTx = "EXECUTED_MULTISIG_TRANSACTION"
}

protocol MultisigNotification {
    var localizedMessage: String { get }
    init?(payload: NotificationPayload)
}
