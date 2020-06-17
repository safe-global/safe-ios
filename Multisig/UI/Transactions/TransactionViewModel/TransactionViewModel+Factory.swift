//
//  TransactionViewModel+Factory.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension TransactionViewModel {

    static func create(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        switch tx.txType {
        case .some(.ethereum):

            if let transfers = tx.transfers, !transfers.isEmpty {
                return transfers.map {
                    TransferTransactionViewModel(transfer: $0, tx: tx, safe: info)
                }

            } else if MethodRegistry.Ether.isValid(tx) {
                return [TransferTransactionViewModel(tx, info)]

            } else {
                return [CustomTransactionViewModel(tx, info)]
            }
        case .some(.multiSig):

            if MethodRegistry.GnosisSafeSettings.isValid(tx) {
                return [SettingChangeTransactionViewModel(tx, info)]

            } else if MethodRegistry.GnosisSafeMasterCopy.isValid(tx) {
                return [ChangeMasterCopyTransactionViewModel(tx, info)]

            } else if MethodRegistry.ERC20.isValid(tx) ||
                MethodRegistry.ERC721.isValid(tx) ||
                MethodRegistry.Ether.isValid(tx) {
                return [TransferTransactionViewModel(tx, info)]
            }
            fallthrough
        default:
            return [CustomTransactionViewModel(tx, info)]
        }
    }

}
