//
//  WCWalletRegistry.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// https://github.com/WalletConnect/walletconnect-registry
class WalletsDataSource {
    static let shared = WalletsDataSource()

    let wallets: [WalletEntry]

    init() {
        let path = Bundle.main.path(forResource: "wallets", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        wallets = try! JSONDecoder().decode([String: WalletEntry].self, from: data).values.map { $0 }
    }
}

struct WalletEntry: Decodable {
    struct Mobile: Decodable {
        let native: String
        let universal: String
    }
    struct Metadata: Decodable {
        let shortName: String
    }
    let name: String
    let homepage: String
    let chains: [String]
    let mobile: Mobile
    let metadata: Metadata
}
