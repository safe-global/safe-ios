//
//  SafeRelayService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

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

class TokenRegistry {

    private var response: TokensRequest.Response?
    private var blockchainTokens: [Address: TokensRequest.Token] = [:]

    init() {
        blockchainTokens = [Address.zero:
            .init(address: .init(.zero),
                  logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(Address.zero.checksummed).png",
                  default: nil,
                  name: "Ether",
                  symbol: "ETH",
                  description: nil,
                  decimals: .init(18),
                  websiteUri: nil,
                  gas: nil)]
    }

    func update() {
        if let tokens = try? App.shared.safeRelayService.tokens() {
            response = tokens
        }
    }

    private func cachedToken(address: Address) -> TokensRequest.Token? {
        response?.results.first { $0.address.address == address }
    }

    private func blockchainToken(address: Address) -> TokensRequest.Token? {
        if address == EthRegistrar.address {
            return .init(address: .init(address),
                         logoUri: nil,
                         default: nil,
                         name: "ENS",
                         symbol: "ENS",
                         description: nil,
                         decimals: .init(0),
                         websiteUri: nil,
                         gas: nil)
        }

        let erc721 = ERC721(address)
        if let is721 = try? erc721.supportsInterface(ERC721.Selectors.safeTransferFrom), is721 {
            return .init(address: .init(address),
                         logoUri: nil,
                         default: nil,
                         name: (try? erc721.name()) ?? "Unknown",
                         symbol: (try? erc721.symbol()) ?? "",
                         description: nil,
                         decimals: .init(0),
                         websiteUri: nil,
                         gas: nil)
        }

        let erc20 = ERC20Metadata(address)
        return .init(address: .init(address),
                     logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.checksummed).png",
                     default: nil,
                     name: (try? erc20.name()) ?? "Unknown",
                     symbol: (try? erc20.symbol()) ?? "",
                     description: nil,
                     decimals: .init((try? erc20.decimals()) ?? 0),
                     websiteUri: nil,
                     gas: nil)
    }

    subscript(address: String) -> TokensRequest.Token? {
        guard let address = Address(address) else { return nil }
        return self[address]
    }

    subscript(address: Address) -> TokensRequest.Token? {
        if response == nil {
            update()
        }

        if let token = cachedToken(address: address) {
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
        let address: AddressString
        let logoUri: String?
        let `default`: Bool?
        let name: String
        let symbol: String
        let description: String?
        let decimals: UInt256String
        let websiteUri: String?
        let gas: Bool?
    }

}
