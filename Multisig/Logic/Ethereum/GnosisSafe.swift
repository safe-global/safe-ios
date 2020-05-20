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

    var versions: [(masterCopy: Address, version: String)] = [
        (Address("0xAC6072986E985aaBE7804695EC2d8970Cf7541A2")!, "0.0.2"),
        (Address("0x8942595A2dC5181Df0465AF0D7be08c8f23C93af")!, "0.1.0"),
        (Address("0xb6029EA3B2c51D09a50B53CA8012FeEB05bDa35A")!, "1.0.0"),
        (Address("0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")!, "1.1.1")
    ]

    func version(masterCopy: Address) -> VersionStatus {
        guard let versionIndex = versions.firstIndex(where: { $0.masterCopy == masterCopy }) else {
            return .unknown
        }
        let version = versions[versionIndex].version
        let isUpToDate = versionIndex == versions.count - 1
        return isUpToDate ? .upToDate(version) : .upgradeAvailable(version)
    }

}
