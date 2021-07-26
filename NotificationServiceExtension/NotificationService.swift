//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 05.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    static var coreData: CoreDataProtocol = CoreDataStack()

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    // called on background thread
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = bestAttemptContent else { return }

        do {
            let notification = try MultisigNotification(from: content.userInfo)
            notification.loadContent { contentOrNil in
                guard let infoContent = contentOrNil else { return }

                content.title = infoContent.title
                content.body = infoContent.body
                content.badge = 1
                contentHandler(content)
            }
        } catch {
            print("Failed to parse notification: \(error)")
            contentHandler(content)
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
