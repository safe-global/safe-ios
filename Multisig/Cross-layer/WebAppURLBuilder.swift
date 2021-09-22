//
//  WebAppURLBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

enum WebAppURLBuilder {
    typealias ChainID = String

    private static let urlRegistry: [ChainID: String] = [
        // eth mainnet
        "1": "https://gnosis-safe.io",
        // xdai
        "100": "https://xdai.gnosis-safe.io",
        // polygon
        "137": "https://polygon.gnosis-safe.io",
        // binance smart chain
        "56": "https://bsc.gnosis-safe.io",
        // energy web chain
        "246": "https://ewc.gnosis-safe.io",
        // arbitrum rollup
        "42161": "https://arbitrum.gnosis-safe.io",
        // rinkeby test network
        "4": "https://rinkeby.gnosis-safe.io",
        // volta chain
        "73799": "https://volta.gnosis-safe.io",
    ]

    static func url(chain: ChainID, safe: Address) -> URL? {
        guard let base = urlRegistry[chain] else { return nil }
        let path = "/app/#/safes/\(safe.checksummed)/balances/collectibles"
        let url = URL(string: base + path)
        return url
    }
}
