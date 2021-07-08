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
    #warning ("This one should be changed when proper implementation of 1.3.0 support")
    var versions: [(implementation: Address, version: String)] = [
        ("0xAC6072986E985aaBE7804695EC2d8970Cf7541A2", "0.0.2"),
        ("0x8942595A2dC5181Df0465AF0D7be08c8f23C93af", "0.1.0"),
        ("0xb6029EA3B2c51D09a50B53CA8012FeEB05bDa35A", "1.0.0"),
        ("0xaE32496491b53841efb51829d6f886387708F99B", "1.1.0"),
        ("0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F", "1.1.1"),
        ("0x6851d6fdfafd08c0295c392436245e5bc78b0185", "1.2.0"),
        ("0x3E5c63644E683549055b9Be8653de26E0B4CD36E", "1.3.0"),
        ("0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552", "1.3.0")
    ]

    var supportedVersions: [String] = ["1.0.0", "1.1.0", "1.1.1", "1.2.0", "1.3.0"]

    var fallbackHandlers:[(fallbackHandler: Address, label: String)] = [("0xd5D82B6aDDc9027B22dCA772Aa68D5d74cdBdF44", "DefaultFallbackHandler")]

    func fallbackHandlerInfo(_ info: AddressInfo?) -> AddressInfo? {
        guard let info = info, !info.address.isZero else {
            return nil
        }

        var result = info
        guard let handler = fallbackHandlers.first(where: { $0.fallbackHandler == info.address }) else {
            result.name = info.name ?? "Unknown"
            return result
        }

        result.name = handler.label
        return result
    }

    func version(implementation: Address) -> VersionStatus {
        guard let versionIndex = versions.firstIndex(where: { $0.implementation == implementation }) else {
            return .unknown
        }
        let version = versions[versionIndex].version
        // Here we will consider both 1.1.1 & 1.2.0 are up to date until web interface allow to upgrade to 1.2.0
        let isUpToDate = versionIndex == versions.count - 1 || versionIndex == versions.count - 2
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
