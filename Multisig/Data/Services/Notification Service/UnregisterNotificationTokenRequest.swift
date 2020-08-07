//
//  UnregisterNotificationTokenRequest.swift
//  Multisig
//
//  Created by Moaaz on 8/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct UnregisterNotificationTokenRequest: JSONRequest {
    let deviceID: UUID
    let address: String

    var httpMethod: String { return "DELETE" }
    var urlPath: String { return "/api/v1/notifications/devices/\(deviceID)/safes/\(address)/" }

    typealias ResponseType = Response

    init(deviceID: UUID, address: Address) {
        self.address = address.checksummed
        self.deviceID = deviceID
    }

    struct Response: Decodable {
        
    }
}

extension SafeTransactionService {
    func unregister(deviceID: UUID, address: Address) throws  {
        try execute(request: UnregisterNotificationTokenRequest(deviceID: deviceID, address: address))
    }
}
