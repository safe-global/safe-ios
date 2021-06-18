//
//  TokenRegistry.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class TokenRegistry {
    func networkToken() -> Token {
        Token(type: .erc20,
              address: .ether,
              logo: logo(.ether),
              name: "Ether",
              symbol: "ETH",
              decimals: 18)
    }

    private func logo(_ address: Address) -> URL? {
        URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address.checksummed).png")
    }
}
