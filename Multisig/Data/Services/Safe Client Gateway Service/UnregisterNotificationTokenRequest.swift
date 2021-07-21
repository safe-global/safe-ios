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
    let chainId: String
    
    var httpMethod: String { return "DELETE" }
    var urlPath: String { return "/v1/chains/\(chainId)/notifications/devices/\(deviceID)/safes/\(address)/" }

    typealias ResponseType = EmptyResponse

    init(deviceID: String, address: Address, chainId: String) {
        self.address = address.checksummed
        self.deviceID = deviceID.lowercased()
        self.chainId = chainId
    }

    struct EmptyResponse: Decodable {
        // empty
    }
}

extension SafeClientGatewayService {
    @discardableResult
    func unregister(deviceID: String, address: Address, chainId: String) -> URLSessionTask?  {
        asyncExecute(request:
                        UnregisterNotificationTokenRequest(deviceID: deviceID, address: address, chainId: chainId))
            {_ in }
    }
}
