//
//  MethodRegistry+ERC20.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {

    enum ERC20 {

        struct Transfer: SmartContractMethodCall {
            static let signature = MethodSignature("transfer", "address", "uint256")
            let to: Address
            let amount: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let to = data.parameters[0].addressValue,
                    let amount = data.parameters[1].uint256Value else {
                        return nil
                }
                (self.to, self.amount) = (to, amount)
            }
        }

        struct TransferFrom: SmartContractMethodCall {
            static let signature = MethodSignature("transferFrom", "address", "address", "uint256")
            let from: Address
            let to: Address
            let amount: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let from = data.parameters[0].addressValue,
                    let to = data.parameters[1].addressValue,
                    let amount = data.parameters[2].uint256Value else {
                        return nil
                }
                (self.from, self.to, self.amount) = (from, to, amount)
            }
        }

        #warning("TODO: tx.contractInfo.type == ContractInfoType.ERC20")
        static func isValid(_ tx: Transaction) -> Bool {
            tx.operation == .call &&
                tx.dataDecoded != nil &&
                (Transfer(data: tx.dataDecoded!) != nil ||
                    TransferFrom(data: tx.dataDecoded!) != nil)
        }

    }

}
