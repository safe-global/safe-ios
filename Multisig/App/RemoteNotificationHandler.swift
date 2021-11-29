//
//  RemoteNotificationHandler.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Firebase

class RemoteNotificationHandler {

    var transactionDetailsPayload: Data?

    @UserDefault(key: "io.gnosis.multisig.deviceID")
    private var storedDeviceID: String?

    @EnumDefault(key: "io.gnosis.multisig.authorizationStatus")
    private var authorizationStatus: UNAuthorizationStatus?

    @UserDefault(key: "io.gnosis.multisig.pushToken")
    private var token: String?

    func setUpMessaging(delegate: MessagingDelegate & UNUserNotificationCenterDelegate) {
        logDebug("Setting up notification handling")
        Messaging.messaging().delegate = delegate

        // https://firebase.google.com/docs/cloud-messaging/ios/client
        // for devices running iOS 10 and above, you must assign your delegate object to the UNUserNotificationCenter
        // object to receive display notifications, and the FIRMessaging object to receive data messages,
        // before your app finishes launching.
        UNUserNotificationCenter.current().delegate = delegate
    }

    // MARK: - Events

    func appStarted() {
        logDebug("App started")
        if storedDeviceID == nil {
            storedDeviceID = UUID().uuidString
        }
        monitorAuthorizationStatus()
    }

    func appEnteredForeground() {
        logDebug("App Entered Foreground")
        cleanUpDeliveredNotifications()
    }

    func pushTokenUpdated(_ token: String) {
        logDebug("Push token updated")
        self.token = token
        if authorizationStatus != nil {
            registerAll()
        }
    }

    func safeAdded(address: Address) {
        logDebug("Safe added: \(address)")
        if authorizationStatus == nil {
            requestUserPermissionAndRegister()
        } else {
            registerAll()
        }
    }

    func safeRemoved(address: Address, chainId: String) {
        unregister(address: address, chainId: chainId)
    }

    /// For add / remove signing key
    func signingKeyUpdated() {
        logDebug("Signing key updated")
        registerAll()
    }

    func received(notification userInfo: [AnyHashable: Any]) {
        assert(Thread.isMainThread)
        logDebug("Received notification: \(userInfo)")
        self.showDetails(userInfo)
    }

    // MARK: - implementation

    private func cleanUpDeliveredNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            logDebug("Cleaning up delivered notifications")
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }

    private func monitorAuthorizationStatus() {
        if let previousAuthorization = authorizationStatus {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                logDebug("Old permission: \(previousAuthorization), new permission: \(settings.authorizationStatus)")
                if settings.authorizationStatus.hasPermission && !previousAuthorization.hasPermission {
                    // authorization changed to granted
                    self.requestUserPermissionAndRegister()
                } else {
                    // authorization either not changed or not granted
                    self.setStatus(settings.authorizationStatus)

                    if settings.authorizationStatus.hasPermission {
                        self.registerAll()
                    }
                }
            }
        }
    }

    var needsToRequestNotificationPermission: Bool {
        authorizationStatus == nil && Safe.count > 0
    }

    func requestUserPermissionAndRegister() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.requestUserPermissionAndRegister() }
            return
        }
        logDebug("requesting permissions for notifications")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                LogService.shared.error("Notification authorization error: \(error)")
                return
            }
            if granted {
                logDebug("User gave permission for notifications")

                DispatchQueue.main.async {
                    logDebug("registering remote notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                }

                // At the time when permission granted, the token will be
                // already set, so we need to register all stored safes
                self.registerAll()
            }
            self.updateAuthorizationStatus()
        }
    }

    private func setStatus(_ status: UNAuthorizationStatus) {
        DispatchQueue.main.async {
            logDebug("Saving authorization status")
            self.authorizationStatus = status
            self.track(status)
        }
    }

    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            logDebug("Got current notification settings")
            self.setStatus(settings.authorizationStatus)
        }
    }

    private func track(_ status: UNAuthorizationStatus) {
        Tracker.setPushInfo(status.trackingStatus.rawValue)
    }

    /// Constructs the hash for the registration request and signs with all available
    /// private keys stored.
    ///
    /// - Parameters:
    ///   - safes: List of safe addresses to register for, checksummed, sorted lexicographically.
    ///   - deviceID: UUID of the device to register
    ///   - token: Push token to register
    ///   - timestamp: Unix timestamp or nil. If nil, the current time will be used.
    /// - Throws: Error in case of database failures, or private key signing errors
    /// - Returns: If there are any keys, then returns preimage of the hash, the hash that was signed, timestamp used, and array of signatures corresponding to the signing keys.
    static func sign(safes: [String], deviceID: String, token: String, timestamp: String) throws -> (preimage: String, hash: String, signatures: [String])? {

        // sign the registration data by each private key.
        var privateKeys = try KeyInfo.keys(types: [.deviceImported, .deviceGenerated])
            .compactMap { try $0.privateKey() }

        // get delegate keys for signing
        let delegateKeys = try KeyInfo.keys(types: [.ledgerNanoX])
            .compactMap { keyInfo -> PrivateKey? in
                if let delegateAddress = keyInfo.delegateAddressString,
                   let address = Address(delegateAddress),
                   let privateKey = try PrivateKey.key(address: address) {
                    return privateKey
                }
                return nil
            }

        privateKeys += delegateKeys

        guard !privateKeys.isEmpty,
              !safes.isEmpty else {
            return nil
        }

        let hashPreimage = [
            "gnosis-safe",
            timestamp,
            deviceID,
            token,
            safes.joined()
        ].joined()

        let hash = EthHasher.hash(hashPreimage)

        let signatures: [String] = try privateKeys.map { key in
            let sig = try key.sign(hash: hash)
            return sig.hexadecimal
        }
        return (hashPreimage, hash.toHexStringWithPrefix(), signatures)
    }

    private func unregister(address: Address, chainId: String) {
        App.shared.clientGatewayService.unregister(deviceID: self.storedDeviceID!,
                                                   address: address,
                                                   chainId: chainId)
    }

    private func registerAll() {
        guard let pushToken = token else { return }
        guard let deviceID = storedDeviceID?.lowercased() else {
            assertionFailure("Programmer error: missing device ID")
            return
        }

        do {
            let appConfig = App.configuration.app
            let timestamp = String(format: "%.0f", Date().timeIntervalSince1970)

            var safeRegistration: [SafeRegistration] = []
            for chainSafes in Chain.chainSafes() {
                let safes = chainSafes.safes
                    .compactMap { $0.address }
                    .compactMap { Address($0) }
                    .map { $0.checksummed }
                    .sorted()
                guard let signResult = try Self.sign(safes: safes,
                                                     deviceID: deviceID,
                                                     token: pushToken,
                                                     timestamp: timestamp) else { continue }
                
                safeRegistration.append(SafeRegistration(chainId: chainSafes.chain.id!, safes: safes,
                                                         signatures: signResult.signatures))
            }

            App.shared.clientGatewayService.registerNotification(uuid: deviceID,
                                                                 cloudMessagingToken: pushToken,
                                                                 buildNumber: appConfig.buildVersion,
                                                                 bundle: appConfig.bundleIdentifier,
                                                                 version: appConfig.marketingVersion,
                                                                 timestamp: timestamp,
                                                                 safeRegistrations: safeRegistration) { _ in }
        } catch {
            logError("Failed to register device", error)
        }
    }

    private func showDetails(_ userInfo: [AnyHashable : Any]) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let payload = NotificationPayload(userInfo: userInfo)
        
        guard let rawAddress = payload.address,
            let safeAddress = Address(rawAddress),
            let chainId = payload.chainId,
            let chain = Chain.by(chainId) else { return }

        guard Safe.exists(safeAddress.checksummed, chainId: chain.id!) else {
            unregister(address: safeAddress, chainId: chain.id!)
            return
        }

        Safe.select(address: rawAddress, chainId: chain.id!)

        if let safeTxHash = payload.safeTxHash,
           let hashData = Data(exactlyHex: safeTxHash) {

            transactionDetailsPayload = hashData

            NotificationCenter.default.post(name: .confirmationTxNotificationReceived, object: nil)

        } else if ["INCOMING_ETHER", "INCOMING_TOKEN"].contains(payload.type) {
            NotificationCenter.default.post(name: .incommingTxNotificationReceived, object: nil)
        } else if ["EXECUTED_MULTISIG_TRANSACTION", "NEW_CONFIRMATION", "CONFIRMATION_REQUEST"].contains(payload.type) {
            NotificationCenter.default.post(name: .queuedTxNotificationReceived, object: nil)
        }
    }
 }

fileprivate func logDebug(_ msg: String) {
    LogService.shared.debug("PUSH: " + msg)
}

fileprivate func logError(_ msg: String, _ error: Error) {
    LogService.shared.error(msg + ": \(error)", error: error)
}

extension UNAuthorizationStatus {
    var hasPermission: Bool {
        self == .authorized || self == .provisional
    }
}

extension UNAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .authorized: return "Authorized (granted)"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional (granted)"
        case .ephemeral: return "Ephemeral (granted)"
        @unknown default: return "Unknown: \(rawValue)"
        }
    }
}

extension UNAuthorizationStatus {
    fileprivate var trackingStatus: TrackingPushState {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return .enabled
        case .denied:
            return .disabled
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
