//
//  SafeBalancesRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SafeBalancesRequest: JSONRequest {
    let address: String

    var httpMethod: String { return "GET" }
    var urlPath: String { return "/api/v1/safes/\(address)/balances/usd/" }

    typealias ResponseType = [Response]

    init(address: Address) {
        self.address = address.checksummed
    }

    struct Response: Decodable {
        let tokenAddress: AddressString? // nil == Ether
        let token: Token? // nil == Ether
        let balance: UInt256String
        let balanceUsd: String

        struct Token: Decodable {
            let name: String
            let symbol: String
            let decimals: UInt256String
            let logoUri: String
        }
    }
}

extension SafeTransactionService{

    func safeBalances(at address: Address) throws -> [SafeBalancesRequest.Response] {
        try execute(request: SafeBalancesRequest(address: address))
    }

}
