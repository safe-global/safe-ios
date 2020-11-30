//
//  UnregisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct UnregisterNotificationTokenRequest: JSONRequest {
    let deviceID: String
    let address: String

    var httpMethod: String { return "DELETE" }
    var urlPath: String { return "/api/v1/notifications/devices/\(deviceID)/safes/\(address)/" }

    typealias ResponseType = EmptyResponse

    init(deviceID: String, address: Address) {
        self.address = address.checksummed
        self.deviceID = deviceID
    }

    struct EmptyResponse: Decodable {
        // empty
    }
}

extension SafeTransactionService {
    func unregister(deviceID: String, address: Address) throws  {
        try execute(request: UnregisterNotificationTokenRequest(deviceID: deviceID, address: address))
    }
}
