//
//  GnosisSafe.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version

class GnosisSafe {

    enum VersionStatus: Equatable {
        case upToDate(String)
        case upgradeAvailable(String)
        case unknown
    }

    private var minimumSupportedVersion: Version { Version("1.0.0")! }
    private var maximumSupportedVersion: Version { Version("1.3.0")! }

    func isSupported(_ version: String) -> Bool {
        if let version = Version(version), version >= minimumSupportedVersion && version <= maximumSupportedVersion {
            return true
        }
        
        return false
    }
}
