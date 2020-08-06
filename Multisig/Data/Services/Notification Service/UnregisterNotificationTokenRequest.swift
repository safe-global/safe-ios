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
    let addresses: [String]

    var httpMethod: String { return "POST" }
    var urlPath: String { return "/api/v1/notifications/unregister" }

    typealias ResponseType = [Response]

    init(deviceID: UUID, addresses: [Address]) {
        self.addresses = addresses.map {$0.checksummed }
        self.deviceID = deviceID
    }

    struct Response: Decodable {
        
    }
}

extension SafeTransactionService {
    
    @discardableResult
    func unregister(deviceID: UUID, addresses: [Address]) throws -> [UnregisterNotificationTokenRequest.Response] {
        try execute(request: UnregisterNotificationTokenRequest(deviceID: deviceID, addresses: addresses))
    }

}
