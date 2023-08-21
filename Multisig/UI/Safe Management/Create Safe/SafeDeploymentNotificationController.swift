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
        let safeAddress = safe.addressValue.ellipsized()
        let shortName = safe.chain!.shortName ?? ""
        let shortNamePrefix = shortName.isEmpty ? "" : "\(shortName):"
        let adressString = "\(shortNamePrefix)\(safeAddress)"
        let chainName = safe.chain!.name ?? ""
        let safeName = safe.name ?? safeAddress
        let safeNameForTitle = safeName.ellipsize()

        let notificationId: String
        let content = UNMutableNotificationContent()
        switch safe.safeStatus {
        case .deployed:
            content.title = #"Safe "\#(safeNameForTitle)" created!"#
            content.userInfo["type"] = "safeCreated"
            notificationId = "safeCreated_\(safe.chain!.id!):\(safe.address!)"

        case .deploymentFailed:
            content.title = #"Safe "\#(safeName)" creation failed"#
            content.userInfo["type"] = "safeCreationFailed"
            notificationId = "safeCreationFailed_\(safe.chain!.id!):\(safe.address!)"

        default:
            return
        }

        content.body = "\(adressString) (\(chainName))"
        content.userInfo["safe"] = safe.address!
        content.userInfo["chainId"] = safe.chain!.id!

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

    static func isSafeCreatedNotification(_ info: [AnyHashable: Any]) -> Bool {
        guard let type = info["type"] as? String else { return false }
        let known = ["safeCreated", "safeCreationFailed"].contains(type)
        return known
    }

    static func handleSafeCreatedNotification(userInfo: [AnyHashable: Any]) {
        let address: String = userInfo["safe"] as! String
        let chainId: String = userInfo["chainId"] as! String
        let route = NavigationRoute.showAssets(address, chainId: chainId)
        CompositeNavigationRouter.shared.navigate(to: route)
    }
}

extension String {
    func ellipsize(maxLength: Int = 14) -> String {
        if self.count > maxLength {
            var shortString = self.prefix(maxLength)
            return shortString.trimmingCharacters(in: .whitespaces) + "…"
        }
        return self
    }
}
