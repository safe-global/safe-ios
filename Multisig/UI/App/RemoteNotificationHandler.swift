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
        @unknown default: return "Unknown: \(rawValue)"
        }
    }
}

class RemoteNotificationHandler {
    var token: String?
    // This is temporary, will be removed when we store device id in database
    var deviceID: UUID? {
        set {
            storedDeviceID = newValue?.uuidString
        }
        get {
            guard let storedDeviceID = storedDeviceID else { return nil }

            return UUID(uuidString: storedDeviceID)
        }
    }

    @UserDefault(key: "deviceID")
    var storedDeviceID: String?

    func setUpMessaging(delegate: MessagingDelegate & UNUserNotificationCenterDelegate) {
        log("Setting up notification handling")
        Messaging.messaging().delegate = delegate

        // https://firebase.google.com/docs/cloud-messaging/ios/client
        // for devices running iOS 10 and above, you must assign your delegate object to the UNUserNotificationCenter
        // object to receive display notifications, and the FIRMessaging object to receive data messages,
        // before your app finishes launching.
        UNUserNotificationCenter.current().delegate = delegate
    }

    // MARK: - Events

    func appStarted() {
        log("App started")
        monitorAuthorizationStatus()
    }

    func appEnteredForeground() {
        log("App Entered Foreground")
        cleanUpDeliveredNotifications()
    }

    func pushTokenUpdated(_ token: String) {
        log("Push token updated")
        save(token: token)
        if authorizationStatus != nil {
            registerAll()
        }
    }

    func safeAdded(address: Address) {
        log("Safe added: \(address)")
        if authorizationStatus == nil {
            requestUserPermissionAndRegister()
        } else {
            register(addresses: [address])
        }
    }

    func safeRemoved(address: Address) {
        log("Safe removed: \(address)")
        unregister(address: address)
    }

    func received(notification userInfo: [AnyHashable: Any]) {
        log("Received notification: \(userInfo)")
        assert(Thread.isMainThread)
        log("Clearing badge and opening screens")
        UIApplication.shared.applicationIconBadgeNumber = 0

        let payload = NotificationPayload(userInfo: userInfo)
        do {
            guard let rawAddress = payload.address,
                Address(rawAddress) != nil,
                try Safe.exists(rawAddress) else { return }
            Safe.select(address: rawAddress)
            App.shared.viewState.switchTab(.transactions)

            if payload.type == "EXECUTED_MULTISIG_TRANSACTION" || payload.type == "NEW_CONFIRMATION",
                let hash = payload.safeTxHash {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    App.shared.viewState.presentedSafeTxHash = hash
                }
            }
        } catch {
            LogService.shared.error("Error during opening notification: \(error)")
        }
    }

    // MARK: - implementation

    @EnumDefault(key: "io.gnosis.multisig.authorizationStatus")
    var authorizationStatus: UNAuthorizationStatus?

    private func cleanUpDeliveredNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            log("Cleaning up delivered notifications")
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }

    private func monitorAuthorizationStatus() {
        if let previousAuthorization = authorizationStatus {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                log("Old permission: \(previousAuthorization), new permission: \(settings.authorizationStatus)")
                if settings.authorizationStatus.hasPermission && !previousAuthorization.hasPermission {
                    log("Granted permission")
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
        log("requesting permissions for notifications")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                LogService.shared.error("Notification authorization error: \(error)")
                return
            }
            if granted {
                log("User gave permission for notifications")
                DispatchQueue.main.async {
                    log("registering remote notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                }

                // At the time when permission granted the token will be already set so we need to register all stored safes
                if self.authorizationStatus != nil {
                    self.registerAll()
                }
            }
            self.updateAuthorizationStatus()
        }
    }

    private func setStatus(_ status: UNAuthorizationStatus) {
        DispatchQueue.main.async {
            log("Saving authorization status")
            self.authorizationStatus = status
        }
    }

    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            log("Got current notification settings")
            self.setStatus(settings.authorizationStatus)
        }
    }

    func save(token: String) {
        self.token = token
    }
    func register(addresses: [Address]) {
        guard let token = self.token else { return }
        DispatchQueue.global(qos: .background).async {
            let appConfig = App.configuration.app
            do {
                let response = try App.shared.safeTransactionService.register(deviceID: self.deviceID,
                                                                              safes: addresses, token: token,
                                                                              bundle: appConfig.bundleIdentifier,
                                                                              version: appConfig.marketingVersion,
                                                                              buildNumber: appConfig.buildVersion)
                self.deviceID = response.uuid
            } catch {
                log("Failed to register device")
            }
        }
    }

    func unregister(address: Address) {
        guard let deviceID = deviceID else { return }
        DispatchQueue.global(qos: .background).async {
            do {
                try App.shared.safeTransactionService.unregister(deviceID: deviceID, address: address)
            } catch {
                log("Failed to unregister device")
            }
        }
    }
    func registerAll() {
        let addresses = Safe.all.map { Address(exactly: $0.address ?? "") }
        register(addresses: addresses)
    }
 }

fileprivate func log(_ msg: String) {
    LogService.shared.debug("PUSH: " + msg)
}
