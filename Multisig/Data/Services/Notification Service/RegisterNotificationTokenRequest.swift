//
//  RegisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

struct RegisterNotificationTokenRequest: JSONRequest {
    var uuid: String
    var safes: [String]
    var cloudMessagingToken: String
    var bundle: String
    var version: String
    var deviceType: String = "IOS"
    var buildNumber: String
    var timestamp: String?
    var signatures: [String]?

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/notifications/devices/" }

    typealias ResponseType = Response

    struct Response: Decodable {
        let uuid: UUID
        let safes: [String]
        let cloudMessagingToken: String
        let bundle: String
        let version: String
        let deviceType: String
        let buildNumber: Int
    }
}
