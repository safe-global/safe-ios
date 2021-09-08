//
//  WCWalletRegistry.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

/// https://github.com/WalletConnect/walletconnect-registry
class WalletsDataSource {
    static let shared = WalletsDataSource()

    let installedWallets: [InstalledWallet]

    init() {
        let path = Bundle.main.path(forResource: "wallets", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        installedWallets = try! JSONDecoder().decode([String: WalletEntry].self, from: data).values
            .filter { AllowedWallet.schemes.contains($0.mobile.native) }
            .sorted { AllowedWallet($0)!.priority < AllowedWallet($1)!.priority }
            .compactMap { InstalledWallet(walletEntry: $0) }
    }
}

fileprivate struct WalletEntry: Decodable {
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

/// To be able to check by `canOpenURL` we need to add supported schemes to Info.plist. Therefore we hardcode suppported wallets schemes and their icons
fileprivate struct AllowedWallet {
    let priority: Int
    let scheme: String
    let imageName: String

    static let all: [AllowedWallet] = [
        .init(priority: 0, scheme: "metamask:", imageName: "metamask"),
        .init(priority: 1, scheme: "ledgerlive:", imageName: "ledgerlive"),
        .init(priority: 2, scheme: "rainbow:", imageName: "rainbow"),
        .init(priority: 3, scheme: "trust:", imageName: "trust"),
//        .init(priority: 0, scheme: "argent:", imageName: "argent"),
//        .init(priority: 0, scheme: "pillarwallet:", imageName: "pillarwallet"),
//        .init(priority: 0, scheme: "imtoken2:", imageName: "imtoken2"),
//        .init(priority: 0, scheme: "huobiwallet:", imageName: "huobiwallet"),
//        .init(priority: 0, scheme: "tongue:", imageName: "tongue"),
    ]

    static let schemes: [String] = Self.all.map { $0.scheme }

    static func imageName(for scheme: String) -> String? {
        AllowedWallet.all.first { $0.scheme == scheme }?.imageName
    }

    init?(_ wallet: WalletEntry) {
        let allowedWallet = AllowedWallet.all.first { $0.scheme == wallet.mobile.native }
        if let allowedWallet = allowedWallet {
            self.priority = allowedWallet.priority
            self.scheme = allowedWallet.scheme
            self.imageName = allowedWallet.imageName
        } else {
            return nil
        }
    }

    init(priority: Int, scheme: String, imageName: String) {
        self.priority = priority
        self.scheme = scheme
        self.imageName = imageName
    }
}

struct InstalledWallet: Codable {
    let name: String
    let imageName: String
    let scheme: String
    let universalLink: String

    fileprivate init?(walletEntry: WalletEntry) {
        let scheme = walletEntry.mobile.native
        var universalLink = walletEntry.mobile.universal
        if universalLink.last == "/" {
            universalLink = String(universalLink.dropLast())
        }

        guard let schemeUrl = URL(string: scheme), UIApplication.shared.canOpenURL(schemeUrl) else { return nil }

        self.name = walletEntry.name
        self.imageName = walletEntry.imageName
        self.scheme = scheme
        self.universalLink = universalLink
    }
}
