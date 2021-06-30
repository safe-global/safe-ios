//
//  BalancesRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct BalancesRequest: JSONRequest {
    var safeAddress: String
    var chainId: Int
    var fiat: String
    var isTrusted: Bool?
    var isExcludeSpam: Bool?

    var httpMethod: String { "GET" }

    var urlPath: String {
        "/\(chainId)/v1/safes/\(safeAddress)/balances/\(fiat)"
    }

    var query: String? {
        let output = [
            isTrusted.map { "trusted=\($0)"},
            isExcludeSpam.map { "exclude_spam=\($0)" }
        ].compactMap { $0 }.joined(separator: "&")
        return output.isEmpty ? nil : output
    }

    typealias ResponseType = SafeBalanceSummary

}

extension BalancesRequest {
    init(_ address: Address, chainId: Int) {
        self.init(safeAddress: address.checksummed, chainId: chainId, fiat: AppSettings.selectedFiatCode)
    }
}

struct SafeBalanceSummary: Decodable {
    var fiatTotal: String
    var items: [SCGBalance]
}

struct SCGBalance: Decodable {
    var tokenInfo: TokenInfo
    var balance: UInt256String
    var fiatBalance: String
    var fiatConversion: String
}

extension SafeClientGatewayService {
    func balances(address: Address) throws -> SafeBalanceSummary {
        try execute(request: BalancesRequest(address, chainId: chainId))
    }

    func asyncBalances(address: Address, completion: @escaping (Result<SafeBalanceSummary, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: BalancesRequest(address, chainId: chainId), completion: completion)
    }
}
