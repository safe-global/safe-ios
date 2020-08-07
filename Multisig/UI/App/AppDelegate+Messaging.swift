//
//  AppDelegate+Messaging.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Firebase

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        LogService.shared.debug("PUSH: App is in foreground, willPresent notification with userInfo: \(userInfo)")
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        LogService.shared.debug("PUSH: didReceive notification with userInfo: \(userInfo)")
        App.shared.notificationHandler.received(notification: userInfo)
        completionHandler()
    }

}

extension AppDelegate: MessagingDelegate {

    // Firebase calls it on every app restart.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        App.shared.notificationHandler.pushTokenUpdated(fcmToken)
    }

}

