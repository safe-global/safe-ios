//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 14.01.22.
//

import Foundation
import Solidity

public protocol GnosisSafeExecTransaction {
    init(to : Sol.Address, value : Sol.UInt256, data : Sol.Bytes, operation : Sol.UInt8, safeTxGas : Sol.UInt256, baseGas : Sol.UInt256, gasPrice : Sol.UInt256, gasToken : Sol.Address, refundReceiver : Sol.Address, signatures : Sol.Bytes)

    func encode() -> Data
}

extension GnosisSafe_v1_0_0.execTransaction: GnosisSafeExecTransaction {}
extension GnosisSafe_v1_1_1.execTransaction: GnosisSafeExecTransaction {}
extension GnosisSafe_v1_2_0.execTransaction: GnosisSafeExecTransaction {}
extension GnosisSafe_v1_3_0.execTransaction: GnosisSafeExecTransaction {}
extension GnosisSafeL2_v1_3_0.execTransaction: GnosisSafeExecTransaction {}
