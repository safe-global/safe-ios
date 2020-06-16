//
//  GnosisSafeSettings.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {

    enum GnosisSafeSettings {

        struct AddOwnerWithThreshold: SmartContractMethodCall {
            static let signature = MethodSignature("addOwnerWithThreshold", "address", "uint256")
            let address: Address
            let threshold: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let address = data.parameters[0].addressValue,
                    let threshold = data.parameters[1].uint256Value else {
                        return nil
                }
                (self.address, self.threshold) = (address, threshold)
            }
        }

        struct RemoveOwner: SmartContractMethodCall {
            static let signature = MethodSignature("removeOwner", "address", "address", "uint256")
            let prevOwner: Address
            let owner: Address
            let threshold: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let prevOwner = data.parameters[0].addressValue,
                    let owner = data.parameters[1].addressValue,
                    let threshold = data.parameters[2].uint256Value else {
                        return nil
                }
                (self.prevOwner, self.owner, self.threshold) = (prevOwner, owner, threshold)
            }
        }

        struct SwapOwner: SmartContractMethodCall {
            static let signature = MethodSignature("swapOwner", "address", "address", "address")
            let prevOwner: Address
            let oldOwner: Address
            let newOwner: Address

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let prevOwner = data.parameters[0].addressValue,
                    let oldOwner = data.parameters[1].addressValue,
                    let newOwner = data.parameters[2].addressValue else {
                        return nil
                }
                (self.prevOwner, self.oldOwner, self.newOwner) = (prevOwner, oldOwner, newOwner)
            }
        }

        struct ChangeThreshold: SmartContractMethodCall {
            static let signature = MethodSignature("changeThreshold", "uint256")
            let threshold: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let threshold = data.parameters[0].uint256Value else {
                        return nil
                }
                self.threshold = threshold
            }
        }

        struct EnableModule: SmartContractMethodCall {
            static let signature = MethodSignature("enableModule", "address")
            let module: Address

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let module = data.parameters[0].addressValue else {
                        return nil
                }
                self.module = module
            }
        }

        struct DisableModule: SmartContractMethodCall {
            static let signature = MethodSignature("disableModule", "address", "address")
            let prevModule: Address
            let module: Address

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let prevModule = data.parameters[0].addressValue,
                    let module = data.parameters[1].addressValue else {
                        return nil
                }
                (self.prevModule, self.module) = (prevModule, module)
            }
        }

        static let methods: [SmartContractMethodCall.Type] = [
            AddOwnerWithThreshold.self,
            RemoveOwner.self,
            SwapOwner.self,
            ChangeThreshold.self,
            EnableModule.self,
            DisableModule.self
        ]

        static func method(from data: TransactionData) -> SmartContractMethodCall? {
            for method in methods {
                if let value = method.init(data: data) {
                    return value
                }
            }
            return nil
        }

        static func isValid(_ tx: Transaction) -> Bool {
            return tx.to != nil &&
                tx.to == tx.safe &&
                tx.operation == .call &&
                tx.dataDecoded != nil &&
                method(from: tx.dataDecoded!) != nil
        }

    }

}
