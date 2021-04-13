//
//  WCWalletRegistry.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// To be able to check by `canOpenURL` we need to add supported schemes to Info.plist. Therefore we hardcode suppported wallets schemes and their icons
fileprivate struct AllowedWallet {
    let scheme: String
    let imageName: String

    static let all: [AllowedWallet] = [
        .init(scheme: "metamask:", imageName: "metamask"),
        .init(scheme: "trust:", imageName: "trust"),
        .init(scheme: "rainbow:", imageName: "rainbow"),
        .init(scheme: "argent:", imageName: "argent"),
        .init(scheme: "pillarwallet:", imageName: "pillarwallet"),
        .init(scheme: "imtoken2:", imageName: "imtoken2"),
        .init(scheme: "ledgerlive:", imageName: "ledgerlive"),
        .init(scheme: "huobiwallet:", imageName: "huobiwallet"),
        .init(scheme: "tongue:", imageName: "tongue"),
    ]

    static let schemes: [String] = Self.all.map { $0.scheme }

    static func imageName(for scheme: String) -> String? {
        AllowedWallet.all.first { $0.scheme == scheme }?.imageName
    }
}

/// https://github.com/WalletConnect/walletconnect-registry
class WalletsDataSource {
    static let shared = WalletsDataSource()

    let wallets: [WalletEntry]

    init() {
        let path = Bundle.main.path(forResource: "wallets", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        wallets = try! JSONDecoder().decode([String: WalletEntry].self, from: data).values
            .filter { AllowedWallet.schemes.contains($0.mobile.native) }
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

extension WalletEntry {
    var imageName: String {
        AllowedWallet.imageName(for: mobile.native)!
    }
}
