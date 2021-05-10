//
//  Notifications.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let selectedSafeChanged = NSNotification.Name("io.gnosis.safe.selectedSafeChanged")
    static let selectedSafeUpdated = NSNotification.Name("io.gnosis.safe.selectedSafeUpdated")

    static let ownerKeyImported = NSNotification.Name("io.gnosis.safe.ownerKeyImported")
    static let ownerKeyRemoved = NSNotification.Name("io.gnosis.safe.ownerKeyRemoved")
    static let ownerKeyUpdated = NSNotification.Name("io.gnosis.safe.ownerKeyUpdated")


    static let passcodeCreated = NSNotification.Name("io.gnosis.safe.passcodeCreated")
    static let passcodeDeleted = NSNotification.Name("io.gnosis.safe.passcodeDeleted")

    static let selectedFiatCurrencyChanged = NSNotification.Name("io.gnosis.safe.selectedFiatCurrencyChanged")

    static let networkHostReachable = NSNotification.Name("io.gnosis.safe.networkHostReachable")
    static let networkHostUnreachable = NSNotification.Name("io.gnosis.safe.networkHostUnreachable")

    static let incommingTxNotificationReceived = NSNotification.Name("io.gnosis.safe.incommingTxNotification")
    static let queuedTxNotificationReceived = NSNotification.Name("io.gnosis.safe.queuedTxNotificationReceived")
    static let confirmationTxNotificationReceived = NSNotification.Name("io.gnosis.safe.confirmationTxNotificationReceived")

    static let transactionDataInvalidated = NSNotification.Name("io.gnosis.safe.transactionDataInvalidated")


    static let biometricsActivated = NSNotification.Name("io.gnosis.safe.biometricsActivated")
}
