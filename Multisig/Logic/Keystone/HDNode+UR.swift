//
//  HDNode+UR.swift
//  Multisig
//
//  Created by Zhiying Fan on 27/8/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import URRegistry

extension HDNode {
    convenience init?(ur: String) {
        self.init()
        
        if let hdKey = URRegistry.shared.getHDKey(from: ur) {
            publicKey = Data(hex: hdKey.key)
            chaincode = Data(hex: hdKey.chainCode)
        } else {
            return nil
        }
    }
}
