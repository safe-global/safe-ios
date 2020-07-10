//
//  TokenRegistry.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TokenRegistry {

    private var response: TokensRequest.Response?
    private var blockchainTokens: [Address: TokensRequest.Token] = [:]

    var ether: TokensRequest.Token {
        self[AddressRegistry.ether]!
    }

    init() {
        blockchainTokens = [AddressRegistry.ether:
            .init(address: .init(AddressRegistry.ether),
                  logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(AddressRegistry.ether.checksummed).png",
                  name: "Ether",
                  symbol: "ETH",
                  decimals: .init(18))]
    }

    func update() {
        if let tokens = try? App.shared.safeTransactionService.tokens() {
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
                         name: "ENS",
                         symbol: "ENS",
                         decimals: .init(0))
        }

        let erc721 = ERC721(address)
        if let is721 = try? erc721.supportsInterface(ERC721.Selectors.safeTransferFrom), is721 {
            return .init(address: .init(address),
                         logoUri: nil,
                         name: (try? erc721.name()) ?? "Unknown",
                         symbol: (try? erc721.symbol()) ?? "",
                         decimals: .init(0))
        }

        let erc20 = ERC20Metadata(address)
        return .init(address: .init(address),
                     logoUri: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.checksummed).png",
                     name: (try? erc20.name()) ?? "Unknown",
                     symbol: (try? erc20.symbol()) ?? "",
                     decimals: .init((try? erc20.decimals()) ?? 0))
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
