//
//  RegisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct RegisterNotificationTokenRequest: JSONRequest {
    let deviceID: UUID
    let addresses: String
    let cloudMessagingToken: String
    let bundle: String
    let version: String
    let deviceType: String = "IOS"
    let buildNumber: Int
    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/safes/\(address)/notifications/devices/" }

    typealias ResponseType = Response

    init(deviceID: UUID, address: Address, token: String, bundle: String, version: String, buildNumber: Int) {
        self.deviceID = deviceID
        self.address = address.checksummed
        self.cloudMessagingToken = token
        self.bundle = bundle
        self.version = version
        self.buildNumber = buildNumber

    }

    struct Response: Decodable {

    }
}

extension SafeTransactionService {

    @discardableResult
    func register(deviceID: UUID, address: Address, token: String, bundle: String, version: String, buildNumber: Int) throws -> RegisterNotificationTokenRequest.Response {
        return try execute(request: RegisterNotificationTokenRequest(deviceID: deviceID, address: address, token: token, bundle: bundle, version: version, buildNumber: buildNumber))
    }

    @discardableResult
    func register(deviceID: UUID, addresses: [Address], token: String, bundle: String, version: String, buildNumber: Int) throws -> RegisterNotificationTokenRequest.Response {
        for address in addresses {
            try execute(request: RegisterNotificationTokenRequest(deviceID: deviceID, address: address, token: token, bundle: bundle, version: version, buildNumber: buildNumber))
        }
    }
}
