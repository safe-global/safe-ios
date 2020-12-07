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
            register(addresses: [address])
        }
    }

    func safeRemoved(address: Address) {
        logDebug("Safe removed: \(address)")
        unregister(address: address)
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
        } else if Safe.count > 0 {
            requestUserPermissionAndRegister()
        }
    }

    private func requestUserPermissionAndRegister() {
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
        Tracker.shared.setUserProperty(status.trackingStatus.rawValue,
                                       for: TrackingUserProperty.pushInfo)
    }

    private func register(addresses: [Address]) {
        guard let token = self.token else { return }
        queue.async { [unowned self] in
            let appConfig = App.configuration.app
            var timestamp: String?
            if let _ = try? App.shared.keychainService.data(forKey: KeychainKey.ownerPrivateKey.rawValue) {
                timestamp = String(format: "%.0f", Date().timeIntervalSince1970)
            }
            do {
                try App.shared.safeTransactionService
                    .register(deviceID: self.storedDeviceID!,
                              safes: addresses,
                              token: token,
                              bundle: appConfig.bundleIdentifier,
                              version: appConfig.marketingVersion,
                              buildNumber: appConfig.buildVersion,
                              timestamp: timestamp)
            } catch {
                logError("Failed to register device", error)
            }
        }
    }

    private func unregister(address: Address) {
        queue.async { [unowned self] in
            do {
                try App.shared.safeTransactionService.unregister(deviceID: self.storedDeviceID!, address: address)
            } catch {
                logError("Failed to unregister device", error)
            }
        }
    }

    private func registerAll() {
        let addresses = Safe.all.map { Address(exactly: $0.address ?? "") }
        register(addresses: addresses)
    }

    private func showDetails(_ userInfo: [AnyHashable : Any]) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let payload = NotificationPayload(userInfo: userInfo)
        do {
            guard let rawAddress = payload.address,
                let safeAddress = Address(rawAddress) else { return }

            guard try Safe.exists(safeAddress.checksummed) else {
                unregister(address: safeAddress)
                return
            }

            Safe.select(address: rawAddress)
            App.shared.viewState.switchTab(.transactions)

            if ["EXECUTED_MULTISIG_TRANSACTION", "NEW_CONFIRMATION", "CONFIRMATION_REQUEST"].contains(payload.type),
               let safeTxHash = payload.safeTxHash,
               let hashData = Data(exactlyHex: safeTxHash) {
                let vc = TransactionDetailsViewController(safeTxHash: hashData)
                vc.navigationItem.leftBarButtonItem =
                    UIBarButtonItem(barButtonSystemItem: .close, target: vc, action: #selector(CloseModal.closeModal))
                let navController = UINavigationController(rootViewController: vc)
                UIWindow.topMostController()!.present(navController, animated: true)
            }
        } catch {
            logError("Error during opening notification", error)
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
