//
//  MethodRegistry+GnosisSafeMasterCopy.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {
    
    enum GnosisSafeMasterCopy {
        
        struct ChangeMasterCopy: SmartContractMethodCall {
            static let signature = MethodSignature("changeMasterCopy", "address")
            let masterCopy: Address
            
            init?(data: TransactionData) {
                guard data == Self.signature,
                    let masterCopy = data.parameters[0].addressValue else {
                        return nil
                }
                self.masterCopy = masterCopy
            }
        }
        
        static func isValid(_ tx: Transaction) -> Bool {
            tx.to != nil &&
                tx.to == tx.safe &&
                tx.operation == .call &&
                tx.dataDecoded != nil &&
                ChangeMasterCopy(data: tx.dataDecoded!) != nil
        }
    }
    
}
