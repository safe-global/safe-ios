//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 05.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let payload = NotificationPayload(userInfo: bestAttemptContent.userInfo)
            guard let notification = ([
                ExecutedMultisigTransactionNotification.self,
                IncomingTokenNotification.self,
                IncomingEtherNotification.self
            ] as [MultisigNotification.Type])
                .compactMap({ $0.init(payload: payload) })
                .first
            else {
                return
            }
            bestAttemptContent.title = notification.localizedMessage
            bestAttemptContent.badge = 1
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
