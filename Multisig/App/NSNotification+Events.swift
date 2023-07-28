//
//  Notifications.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    // MARK: - Core

    static let selectedSafeChanged = NSNotification.Name("io.gnosis.safe.selectedSafeChanged")
    static let selectedSafeUpdated = NSNotification.Name("io.gnosis.safe.selectedSafeUpdated")

    static let safeCreationUpdate = NSNotification.Name("io.gnosis.safe.safeCreationUpdate")

    static let web3AuthSafeCreationUpdate = NSNotification.Name("io.gnosis.safe.web3AuthSafeCreationUpdate")

    static let chainInfoChanged = NSNotification.Name("io.gnosis.safe.chainInfoChanged")

    static let ownerKeyImported = NSNotification.Name("io.gnosis.safe.ownerKeyImported")
    static let ownerKeyRemoved = NSNotification.Name("io.gnosis.safe.ownerKeyRemoved")
    static let ownerKeyUpdated = NSNotification.Name("io.gnosis.safe.ownerKeyUpdated")
    static let ownerKeyBackedUp = NSNotification.Name("io.gnosis.safe.ownerKeyBackedUp")
    
    static let balanceLoading = NSNotification.Name("io.gnosis.safe.balanceLoading")
    static let balanceUpdated = NSNotification.Name("io.gnosis.safe.balanceUpdated")

    static let transactionDataInvalidated = NSNotification.Name("io.gnosis.safe.transactionDataInvalidated")

    static let incommingTxNotificationReceived = NSNotification.Name("io.gnosis.safe.incommingTxNotification")
    static let queuedTxNotificationReceived = NSNotification.Name("io.gnosis.safe.queuedTxNotificationReceived")
    static let confirmationTxNotificationReceived = NSNotification.Name("io.gnosis.safe.confirmationTxNotificationReceived")
    static let initiateTxNotificationReceived = NSNotification.Name("io.gnosis.safe.initiateTxNotificationReceived")

    static let biometricsActivated = NSNotification.Name("io.gnosis.safe.biometricsActivated")

    // MARK: - WalletConnect

    static let wcConnectingSafeServer = NSNotification.Name("io.gnosis.safe.wcConnectingSafeServer")
    static let wcDidFailToConnectSafeServer = NSNotification.Name("io.gnosis.safe.wcDidFailToConnectSafeServer")
    static let wcDidConnectSafeServer = NSNotification.Name("io.gnosis.safe.wcDidConnectSafeServer")
    static let wcDidDisconnectSafeServer = NSNotification.Name("io.gnosis.safe.wcDidDisconnectSafeServer")

    static let wcConnectingKeyServer = NSNotification.Name("io.gnosis.safe.wcConnectingKeyServer")
    static let wcDidFailToConnectKeyServer = NSNotification.Name("io.gnosis.safe.wcDidFailToConnectKeyServer")
    static let wcDidConnectKeyServer = NSNotification.Name("io.gnosis.safe.wcDidConnectKeyServer")
    static let wcDidDisconnectKeyServer = NSNotification.Name("io.gnosis.safe.wcDidDisconnectKeyServer")

    static let wcDidFailToConnectClient = NSNotification.Name("io.gnosis.safe.wcDidFailToConnectClient")
    static let wcDidConnectClient = NSNotification.Name("io.gnosis.safe.wcDidConnectClient")
    static let wcDidDisconnectClient = NSNotification.Name("io.gnosis.safe.wcDidDisconnectClient")

    // MARK: - Passcode

    static let passcodeCreated = NSNotification.Name("io.gnosis.safe.passcodeCreated")
    static let passcodeDeleted = NSNotification.Name("io.gnosis.safe.passcodeDeleted")
    static let passcodeRequired = NSNotification.Name("global.safe.passcodeRequired")

    // MARK: - Networking

    static let networkHostReachable = NSNotification.Name("io.gnosis.safe.networkHostReachable")
    static let networkHostUnreachable = NSNotification.Name("io.gnosis.safe.networkHostUnreachable")

    // MARK: - Fiat

    static let selectedFiatCurrencyChanged = NSNotification.Name("io.gnosis.safe.selectedFiatCurrencyChanged")

    // MARK: - Experemental

    static let updatedExperemental = NSNotification.Name("io.gnosis.safe.updatedExperemental")

    // MARK: - Addressbook

    static let addressbookChanged = NSNotification.Name("io.gnosis.safe.addressbookChanged")

    // MARK: - Chain settings changed

    static let chainSettingsChanged = NSNotification.Name("io.gnosis.safe.chainSettingsChanged")
}
