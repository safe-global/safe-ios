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

    private var queue = DispatchQueue(label: "RemoteNotificationHandlerQueue")

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

    func safeRemoved(address: Address, networkId: Int) {
        unregister(address: address, networkId: networkId)
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
        Tracker.shared.setPushInfo(status.trackingStatus.rawValue)
    }

    private func register(addresses: [Address]) {
        guard let token = token else { return }
        guard let deviceID = storedDeviceID?.lowercased() else {
            assertionFailure("Programmer error: missing device ID")
            return
        }
        queue.async {
            do {
                let safes = addresses.map { $0.checksummed }.sorted()
                let signResult = try Self.sign(safes: safes, deviceID: deviceID, token: token)
                let appConfig = App.configuration.app

                let request = RegisterNotificationTokenRequest(
                    uuid: deviceID,
                    safes: safes,
                    cloudMessagingToken: token,
                    bundle: appConfig.bundleIdentifier,
                    version: appConfig.marketingVersion,
                    buildNumber: appConfig.buildVersion,
                    timestamp: signResult?.timestamp,
                    signatures: signResult?.signatures)

                // will be changed with new registration request
                guard let networkId = (try? Safe.getSelected())?.network?.id else { return }
                try App.shared.safeTransactionService.execute(request: request, networkId: networkId)
            } catch {
                logError("Failed to register device", error)
            }
        }
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
    static func sign(safes: [String], deviceID: String, token: String, timestamp: String? = nil) throws -> (preimage: String, hash: String, timestamp: String, signatures: [String])? {
        // sign the registration data by each private key.

        let privateKeys = try KeyInfo.keys(types: [.deviceImported, .deviceGenerated])
            .compactMap { try $0.privateKey() }

        guard !privateKeys.isEmpty else {
            return nil
        }

        let timestamp = timestamp ?? String(format: "%.0f", Date().timeIntervalSince1970)

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
        return (hashPreimage, hash.toHexStringWithPrefix(), timestamp, signatures)
    }

    private func unregister(address: Address, networkId: Int) {
        queue.async { [unowned self] in
            do {
                try App.shared.safeTransactionService.unregister(deviceID: self.storedDeviceID!,
                                                                 address: address,
                                                                 networkId: networkId)
            } catch {
                logError("Failed to unregister device", error)
            }
        }
    }

    private func registerAll() {
        let addresses = Safe.all.compactMap { $0.address }.compactMap { Address($0) }
        register(addresses: addresses)
    }

    #warning("TODO: Update when push notifications payload is clear")
    private func showDetails(_ userInfo: [AnyHashable : Any]) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let payload = NotificationPayload(userInfo: userInfo)
        
        guard let rawAddress = payload.address,
            let safeAddress = Address(rawAddress) else { return }

        let network = Network.mainnetChain()

        guard Safe.exists(safeAddress.checksummed, networkId: network.id) else {
            unregister(address: safeAddress, networkId: network.id)
            return
        }

        Safe.select(address: rawAddress, networkId: network.id)

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
