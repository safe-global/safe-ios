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

    private let minimumSupportedVersion = "1.0.0"
    private let latestSupportedVersion = "1.3.0"

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

    func isSupported(_ version: String) -> Bool {
        let compareWithMinResult = minimumSupportedVersion.compareNumeric(version)
        let compareWithMaxResult = version.compareNumeric(latestSupportedVersion)
        if [.orderedAscending, .orderedSame].contains(compareWithMinResult) &&
            [.orderedAscending, .orderedSame].contains(compareWithMaxResult) {
            return true
        }
        
        return false
    }
}
