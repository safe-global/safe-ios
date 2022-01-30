//
//  GnosisSafeSetup_v1_3_0.swift
//  
//
//  Created by Dmitry Bespalov on 30.01.22.
//

import Foundation
import Solidity

public protocol GnosisSafeSetup_v1_3_0 {
    init(_owners : Sol.Array<Sol.Address>, _threshold : Sol.UInt256, to : Sol.Address, data : Sol.Bytes, fallbackHandler : Sol.Address, paymentToken : Sol.Address, payment : Sol.UInt256, paymentReceiver : Sol.Address)

    func encode() -> Data
}

extension GnosisSafe_v1_3_0.setup: GnosisSafeSetup_v1_3_0 {}
extension GnosisSafeL2_v1_3_0.setup: GnosisSafeSetup_v1_3_0 {}
