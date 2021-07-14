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
    var deviceData: DeviceData
    var safeRegistrations: [SafeRegistration]

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/register/notifications/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable {
        // empty
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func registerNotification(
        deviceData: DeviceData,
        safeRegistrations: [SafeRegistration],
        completion: @escaping (Result<RegisterNotificationTokenRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request:RegisterNotificationTokenRequest(deviceData: deviceData,
                                                              safeRegistrations: safeRegistrations), completion: completion)
    }
}

struct DeviceData: Encodable {
    var uuid: String
    var cloudMessagingToken: String
    var buildNumber: String
    var bundle: String
    var deviceType: String = "IOS"
    var version: String
    var timestamp: String?
}

struct SafeRegistration: Encodable {
    var chainId: String
    var safes: [String]
    var signatures: [String]
}
