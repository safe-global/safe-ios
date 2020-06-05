//
//  SafeRelayService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

class SafeRelayService {

    var url: URL
    private let logger: Logger
    private let httpClient: JSONHTTPClient

    init(url: URL, logger: Logger) {
        self.url = url
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
    }

    func tokens() throws -> TokensRequest.Response {
        try httpClient.execute(request: TokensRequest())
    }
}

typealias UInt256 = BigInt

class TokenRegistry {

    private var response: TokensRequest.Response?
    private var blockchainTokens: [Address: TokensRequest.Token] = [:]

    init() {
        blockchainTokens = [Address.zero:
            .init(address: Address.zero.hex(eip55: true),
                  logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(Address.zero.hex(eip55: true)).png",
                  default: nil,
                  name: "Ether",
                  symbol: "ETH",
                  description: nil,
                  decimals: 18,
                  websiteUri: nil,
                  gas: nil)]
    }

    func update() {
        if let tokens = try? App.shared.safeRelayService.tokens() {
            response = tokens
        }
    }

    private func cachedToken(address: String) -> TokensRequest.Token? {
        response?.results.first { $0.address == address }
    }

    private func blockchainToken(address: Address) -> TokensRequest.Token? {
        let contract = ERC20Metadata(address)
        let name = try? contract.name()
        let symbol = try? contract.symbol()
        let decimals = try? contract.decimals()

        if name == nil && symbol == nil {
            let registrar = ENSRegistrar(address)
            if (try? registrar.ens()) != nil {
            return .init(
                address: address.hex(eip55: true),
                logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.hex(eip55: true)).png",
                default: nil,
                name: "ENS",
                symbol: "ENS",
                description: nil,
                decimals: 0,
                websiteUri: nil,
                gas: nil)
            }
        }
        #warning("TODO: replace with issue #86")
        return .init(
            address: address.hex(eip55: true),
            logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.hex(eip55: true)).png",
            default: nil,
            name: name ?? "Unknown",
            symbol: symbol ?? "",
            description: nil,
            decimals: decimals ?? 0,
            websiteUri: nil,
            gas: nil)

    }

    subscript(address: String) -> TokensRequest.Token? {
        guard let address = Address(address) else { return nil }

        if response == nil {
            update()
        }

        if let token = cachedToken(address: address.hex(eip55: true)) {
            return token
        }

        if let token = blockchainTokens[address] {
            return token
        }

        if let token = blockchainToken(address: address) {
            blockchainTokens[address] = token
            return token
        }

        return nil
    }
}

struct TokensRequest: JSONRequest {

    let limit: Int = 3000
    let offset: Int = 0

    var httpMethod: String { "GET" }
    var urlPath: String { "/api/v1/tokens/" }

    var query: String? {
        return "limit=\(limit)&offset=\(offset)"
    }

    typealias Response = PagedResponse<Token>
    typealias ResponseType = Response

    struct Token: Decodable {
        let address: String
        let logoUri: String?
        let `default`: Bool?
        let name: String
        let symbol: String
        let description: String?
        let decimals: Int
        let websiteUri: String?
        let gas: Bool?
    }

}

struct PagedResponse<Item: Decodable>: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Item]
}
