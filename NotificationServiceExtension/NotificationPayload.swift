//
//  NotificationPayload.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

@dynamicMemberLookup
struct NotificationPayload {
    var userInfo: [AnyHashable: Any]

    subscript(dynamicMember member: String) -> String? {
        get {
            userInfo[member] as? String
        }
        mutating set {
            if let value = newValue {
                userInfo[member] = value
            } else {
                userInfo.removeValue(forKey: member)
            }
        }
    }
}
