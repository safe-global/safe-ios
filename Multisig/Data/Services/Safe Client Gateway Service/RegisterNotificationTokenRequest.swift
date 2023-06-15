//
//  RegisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SafeWeb3

struct RegisterNotificationTokenRequest: JSONRequest {
    var uuid: String
    var cloudMessagingToken: String
    var buildNumber: String
    var bundle: String
    let deviceType: String = "IOS"
    var version: String
    var timestamp: String

    var safeRegistrations: [SafeRegistration]

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/v1/register/notifications/" }

    typealias ResponseType = EmptyResponse

    struct EmptyResponse: Decodable {
        // empty
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func registerNotification(
        uuid: String,
        cloudMessagingToken: String,
        buildNumber: String,
        bundle: String,
        version: String,
        timestamp: String,
        safeRegistrations: [SafeRegistration],
        completion: @escaping (Result<RegisterNotificationTokenRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request:RegisterNotificationTokenRequest(uuid: uuid,
                                                              cloudMessagingToken: cloudMessagingToken,
                                                              buildNumber: buildNumber,
                                                              bundle: bundle,
                                                              version: version,
                                                              timestamp: timestamp,
                                                              safeRegistrations: safeRegistrations), completion: completion)
    }
}

struct SafeRegistration: Encodable {
    var chainId: String
    var safes: [String]
    var signatures: [String]
}
