//
//  MethodRegistry+GnosisSafeImplementation.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {
    
    enum GnosisSafeImplementation {
        
        struct ChangeImplementation: SmartContractMethodCall {
            static let signature = MethodSignature("changeMasterCopy", "address")
            let implementation: Address
            
            init?(data: TransactionData) {
                guard data == Self.signature,
                    let implementation = data.parameters[0].addressValue else {
                        return nil
                }
                self.implementation = implementation
            }
        }
        
        static func isValid(_ tx: Transaction) -> Bool {
            tx.txType == .multiSig &&
            tx.to != nil &&
            tx.to == tx.safe &&
            tx.operation == .call &&
            tx.dataDecoded != nil &&
            ChangeImplementation(data: tx.dataDecoded!) != nil
        }
    }
    
}
