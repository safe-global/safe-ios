//
//  SafeDeploymentController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 25.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SafeDeploymentNotificationController {
    static func sendNotification(safe: Safe) {
        let safeName = safe.name ?? ""
        let shortName = safe.chain!.shortName ?? ""
        let safeAddress = safe.addressValue.ellipsized()
        let shortNamePrefix = shortName.isEmpty ? "" : "\(shortName):"
        let adressString = "\(shortNamePrefix)\(safeAddress)"
        let chainName = safe.chain?.name ?? ""
        
        let content = UNMutableNotificationContent()
        content.title = "Safe \"\(safeName)\" created!"
        content.body = "\(adressString) (\(chainName))"
        content.userInfo = ["type":"safeCreated", "safe": safe.address!,  "chainId": safe.chain!.id!]
        
        let notificationId = notificationId(safe: safe)
        // no trigger to deliver immediately
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: nil)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if let error = error {
                LogService.shared.error("Error creating local notification: \(error)")
            }
        }
    }
    
    static func dismissNotification(safe: Safe) {
        let notificationId = notificationId(safe: safe)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    private static func notificationId(safe: Safe) -> String {
        "\(safe.chain!.shortName):\(safe.address!)"
    }

    static func isSafeCreatedNotification(_ info: [AnyHashable: Any]) -> Bool {
        info["type"] as? String == "safeCreated"
    }
    
    static func handleSafeCreatedNotification(userInfo: [AnyHashable : Any]) {
        guard let safe = Safe.by(address: userInfo["safe"] as! String,chainId: userInfo["chainId"] as! String) else { return }
        
        if !safe.isSelected {
            safe.select()
            NotificationCenter.default.post(name: .showBalances, object: self)
        }
    }
}
