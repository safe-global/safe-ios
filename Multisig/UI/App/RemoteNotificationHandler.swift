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

class RemoteNotificationHandler {

    func setUpMessaging(delegate: MessagingDelegate & UNUserNotificationCenterDelegate) {
        Messaging.messaging().delegate = delegate

        // https://firebase.google.com/docs/cloud-messaging/ios/client
        // for devices running iOS 10 and above, you must assign your delegate object to the UNUserNotificationCenter
        // object to receive display notifications, and the FIRMessaging object to receive data messages,
        // before your app finishes launching.
        UNUserNotificationCenter.current().delegate = delegate
    }

    // events

    func appStarted() {
        monitorAuthorizationStatus()
    }

    func appEnteredForeground() {
        processDeliveredNotifications()
    }

    func pushTokenUpdated(_ token: String) {
        LogService.shared.info("MOCK: registering the push token \(token)")
    }

    func safeAdded(address: Address) {
        if authorizationStatus == nil {
            requestUserPermissionAndRegister()
        } else {
            LogService.shared.info("MOCK: registering notifications for one newly added safe \(address)")
        }
    }

    func safeRemoved(address: Address) {
        LogService.shared.info("MOCK: unregistering notifications for one removed safe \(address)")
    }

    func received(notification payload: [AnyHashable: Any]) {
        assert(Thread.isMainThread)
        UIApplication.shared.applicationIconBadgeNumber = 0

        LogService.shared.info("MOCK: received notification: \(payload)")
        // convert to a notification struct
        // if such safe exists
            // switch to the safe
            // open Transaction List
            // if safeHash present
                // push TransactionDetails and pass the transaction hash
        // else
            // ignore
    }

    // MARK: - implementation

    @EnumDefault(key: "io.gnosis.multisig.authorizationStatus")
    var authorizationStatus: UNAuthorizationStatus?

    private func processDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }

    private func monitorAuthorizationStatus() {
        if let previousAuthorization = authorizationStatus {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                // authorization changed: granted
                if settings.authorizationStatus.hasPermission && !previousAuthorization.hasPermission {
                    self.requestUserPermissionAndRegister()
                } else {
                    // authorization either not changed or not granted
                    self.setStatus(settings.authorizationStatus)

                    // if authorized, we can register  all safes
                    if settings.authorizationStatus.hasPermission {
                        LogService.shared.info("MOCK: registering all the safes that currently exist")
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
        LogService.shared.info("MOCK: requesting permissions for notifications")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                LogService.shared.error("Notification authorization error: \(error)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    LogService.shared.info("MOCK: registering remote notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            self.updateAuthorizationStatus()
        }
    }

    private func setStatus(_ status: UNAuthorizationStatus) {
        DispatchQueue.main.async {
            LogService.shared.info("Saving authorization status")
            self.authorizationStatus = status
        }
    }

    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.setStatus(settings.authorizationStatus)
        }
    }

}

