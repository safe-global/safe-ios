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
    static let transactionDataInvalidated = NSNotification.Name("io.gnosis.safe.transactionDataInvalidated")
    static let passcodeCreated = NSNotification.Name("io.gnosis.safe.passcodeCreated")
    static let passcodeDeleted = NSNotification.Name("io.gnosis.safe.passcodeDeleted")
}
