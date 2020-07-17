//
//  MethodRegistry+ERC721.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {

    enum ERC721 {

        struct SafeTransferFrom: SmartContractMethodCall {
            static let signature = MethodSignature("safeTransferFrom", "address", "address", "uint256")
            let from: Address
            let to: Address
            let tokenId: UInt256

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let from = data.parameters[0].addressValue,
                    let to = data.parameters[1].addressValue,
                    let tokenId = data.parameters[2].uint256Value else {
                        return nil
                }
                (self.from, self.to, self.tokenId) = (from, to, tokenId)
            }
        }

        struct SafeTransferFromData: SmartContractMethodCall {
            static let signature = MethodSignature("safeTransferFrom", "address", "address", "uint256", "bytes")
            let from: Address
            let to: Address
            let tokenId: UInt256
            let data: Data

            init?(data: TransactionData) {
                guard data == Self.signature,
                    let from = data.parameters[0].addressValue,
                    let to = data.parameters[1].addressValue,
                    let tokenId = data.parameters[2].uint256Value,
                    let data = data.parameters[3].bytesValue else {
                        return nil
                }
                (self.from, self.to, self.tokenId, self.data) = (from, to, tokenId, data)
            }
        }

    }

}
