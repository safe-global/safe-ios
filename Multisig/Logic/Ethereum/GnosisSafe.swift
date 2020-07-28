//
//  GnosisSafe.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class GnosisSafe {

    enum VersionStatus: Equatable {
        case upToDate(String)
        case upgradeAvailable(String)
        case unknown
    }

    var versions: [(implementation: Address, version: String)] = [
        ("0xAC6072986E985aaBE7804695EC2d8970Cf7541A2", "0.0.2"),
        ("0x8942595A2dC5181Df0465AF0D7be08c8f23C93af", "0.1.0"),
        ("0xb6029EA3B2c51D09a50B53CA8012FeEB05bDa35A", "1.0.0"),
        ("0xaE32496491b53841efb51829d6f886387708F99B", "1.1.0"),
        ("0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F", "1.1.1")
    ]

    var supportedVersions: [String] = ["1.0.0", "1.1.0", "1.1.1"]

    var fallbackHandlers:[(fallbackHandler: Address, label: String)] = [("0xd5D82B6aDDc9027B22dCA772Aa68D5d74cdBdF44", "DefaultFallbackHandler")]

    func hasFallbackHandler(safe: Safe) -> Bool {
        safe.fallbackHandler?.isZero == false
    }

    func fallbackHandlerLabel(fallbackHandler: Address?) -> String {
        guard let fallbackHandler = fallbackHandler else {
            return "Not set"
        }

        guard let handler = fallbackHandlers.first(where: { $0.fallbackHandler == fallbackHandler }) else {
            return "Unknown"
        }

        return handler.label
    }

    func version(implementation: Address) -> VersionStatus {
        guard let versionIndex = versions.firstIndex(where: { $0.implementation == implementation }) else {
            return .unknown
        }
        let version = versions[versionIndex].version
        let isUpToDate = versionIndex == versions.count - 1
        return isUpToDate ? .upToDate(version) : .upgradeAvailable(version)
    }

    func versionNumber(implementation: Address) -> String? {
        versions.first { $0.implementation == implementation }?.version
    }

    func isSupported(_ implementation: Address) -> Bool {
        guard let version = versionNumber(implementation: implementation) else {
            return false
        }
        return supportedVersions.contains(version)
    }
}
