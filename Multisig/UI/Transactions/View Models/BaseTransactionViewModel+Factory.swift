//
//  BaseTransactionViewModel+Factory.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension BaseTransactionViewModel {

    static func create(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [BaseTransactionViewModel] {
        switch tx.txType {
        case .some(.ethereum):

            if let transfers = tx.transfers, !transfers.isEmpty {
                return transfers.map {
                    TransferTransaction(transfer: $0, tx: tx, safe: info)
                }

            } else if MethodRegistry.Ether.isValid(tx) {
                return [TransferTransaction(tx, info)]

            } else {
                return [CustomTransaction(tx, info)]
            }
        case .some(.multiSig):

            if MethodRegistry.GnosisSafeSettings.isValid(tx) {
                return [SettingChangeTransaction(tx, info)]

            } else if MethodRegistry.GnosisSafeMasterCopy.isValid(tx) {
                return [ChangeMasterCopyTransaction(tx, info)]

            } else if MethodRegistry.ERC20.isValid(tx) ||
                MethodRegistry.ERC721.isValid(tx) ||
                MethodRegistry.Ether.isValid(tx) {
                return [TransferTransaction(tx, info)]
            }
            fallthrough
        default:
            return [CustomTransaction(tx, info)]
        }
    }

}
