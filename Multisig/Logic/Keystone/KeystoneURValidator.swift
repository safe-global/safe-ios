//
//  KeystoneQRCodeValidator.swift
//  Multisig
//
//  Created by Zhiying Fan on 17/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

final class KeystoneURValidator {
    static let expectedURTypes = ["crypto-hdkey", "crypto-account"]
    
    static func validate(urType: String) -> Bool {
        return expectedURTypes.contains(urType)
    }
}
