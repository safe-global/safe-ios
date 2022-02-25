//
//  SafeDeploymentController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 25.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SafeDeploymentCotroller {
    static func sendNotification(safe: Safe) {
        let safeName = safe.name ?? ""
        let shortName = safe.chain!.shortName ?? ""
        let safeAddress = safe.addressValue.ellipsized()
        let shortNamePrefix = shortName.isEmpty ? "" : "\(shortName):"
        let adressString = "\(shortNamePrefix)\(safeAddress)"
        let chainName = safe.chain?.name ?? ""
        
        let content = UNMutableNotificationContent()
        content.title = "Safe \"\(safeName)\" created! "
        content.body = "\(adressString) (\(chainName))"
        content.userInfo = ["type":"safeCreated", "safe": safe.address!,  "chainId": safe.chain!.id!]
        
        let uuidString = UUID().uuidString
        // no trigger to deliver immediately
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                // Handle any errors.
                //LogService.shared. ("error: \(error)")
            }
        }
    }
        
    static func isSafeCreatedNotification(_ info: [AnyHashable: Any]) -> Bool {
        info["type"] as? String == "safeCreated"
    }
    
    static func handleSafeCreatedNotification(userInfo: [AnyHashable : Any]) {
        //TODO  Check if safe is already selected. If so, then do nothing
        let safe = Safe.by(
            address: userInfo["safe"] as! String,
            chainId: userInfo["chainId"] as! String
        )
        safe?.select()
        //TODO Select Assets tab!
    }
}
