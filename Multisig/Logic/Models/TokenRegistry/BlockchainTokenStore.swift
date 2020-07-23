//
//  BlockchainTokenStore.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct BlockchainTokenStore {

    func token(address: Address) -> Token? {
        let erc721 = ERC721(address)
        if let supportsERC721 = try?
            erc721.supportsInterface(ERC721.Selectors.safeTransferFrom),
            supportsERC721 {
            let name = try? erc721.name()
            let symbol = try? erc721.symbol()
            return Token(type: .erc721,
                         address: address,
                         logo: BackendTokenStore.logo(address),
                         name: name ?? "ERC721",
                         symbol: symbol ?? "NFT",
                         decimals: 0)
        }
        // treating as erc20 because assumming it is most common case
        let erc20 = ERC20Metadata(address)
        if let name = try? erc20.name(),
            let symbol = try? erc20.symbol(),
            let decimals = try? erc20.decimals() {
            return Token(type: .erc20,
                         address: address,
                         logo: BackendTokenStore.logo(address),
                         name: name,
                         symbol: symbol,
                         decimals: decimals)
        }
        return nil
    }

    func add(_ token: Token) {
        // no-op
    }
}
