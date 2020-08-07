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
        if authorizationStatus != nil {
            register(token: token)
        } else {
            save(token: token)
        }
    }

    func safeAdded(address: Address) {
        log("Safe added: \(address)")
        if authorizationStatus == nil {
            requestUserPermissionAndRegister()
        } else {
            register(safe: address)
        }
    }


    func safeRemoved(address: Address) {
        log("Safe removed: \(address)")
        unregister(safe: address)
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

    // MARK: - Registering in the service
    func register(token: String) {
        log("Registering the push token \(token)")
    }

    func save(token: String) {
        log("Did not receive user permission, save the token for the future: \(token)")
    }

    func register(safe address: Address) {
        log("Registering notifications for one newly added safe \(address)")
    }

    func unregister(safe address: Address) {
        log("Unregistering notifications for one removed safe \(address)")
    }

    func registerAll() {
        log("registering all the safes that currently exist")
    }

}

fileprivate func log(_ msg: String) {
    LogService.shared.debug("PUSH: " + msg)
}
