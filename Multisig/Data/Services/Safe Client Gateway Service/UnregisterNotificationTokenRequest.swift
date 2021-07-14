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
    let networkId: String
    var httpMethod: String { return "DELETE" }
    var urlPath: String { return "/api/v1/chains/\(networkId)/notifications/devices/\(deviceID)/safes/\(address)/" }
    typealias ResponseType = EmptyResponse
    init(deviceID: String, address: Address, networkId: String) {
        self.address = address.checksummed
        self.deviceID = deviceID.lowercased()
        self.networkId = networkId
    }

    struct EmptyResponse: Decodable {
        // empty
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func unregister(deviceID: String, address: Address, networkId: String) -> URLSessionTask?  {
        asyncExecute(request:
                        UnregisterNotificationTokenRequest(deviceID: deviceID, address: address, networkId: networkId))
            {_ in }
    }
}
