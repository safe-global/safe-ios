//
//  RegisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct RegisterNotificationTokenRequest: JSONRequest {
    let uuid: String?
    let safes: [String]
    let cloudMessagingToken: String
    let bundle: String
    let version: String
    let deviceType: String = "IOS"
    let buildNumber: String
    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/notifications/devices/" }

    typealias ResponseType = Response

    init(deviceID: UUID? = nil, safes: [Address], token: String, bundle: String, version: String, buildNumber: String) {
        self.uuid = deviceID?.uuidString.lowercased()
        self.safes = safes.map { $0.checksummed }
        self.cloudMessagingToken = token
        self.bundle = bundle
        self.version = version
        self.buildNumber = buildNumber
    }

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

extension SafeTransactionService {

    func register(deviceID: UUID? = nil, safes: [Address], token: String, bundle: String, version: String, buildNumber: String) throws -> RegisterNotificationTokenRequest.Response {
        return try execute(request: RegisterNotificationTokenRequest(deviceID: deviceID, safes: safes, token: token, bundle: bundle, version: version, buildNumber: buildNumber))
    }
}
