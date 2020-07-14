//
//  TransactionCell+ContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension TransactionCell {

    struct CellContent: View {

        let transaction: TransactionViewModel

        var transfer: TransferTransactionViewModel? {
            transaction as? TransferTransactionViewModel
        }

        var settingChange: SettingChangeTransactionViewModel? {
            transaction as? SettingChangeTransactionViewModel
        }

        var masterCopy: ChangeMasterCopyTransactionViewModel? {
            transaction as? ChangeMasterCopyTransactionViewModel
        }

        var custom: CustomTransactionViewModel? {
            transaction as? CustomTransactionViewModel
        }

        @ViewBuilder var body: some View {
            if custom != nil {
                CustomTransactionCellContent(transaction: custom!)
            } else if transfer != nil {
                TransferCellContent(transaction: transfer!)
            } else if settingChange != nil {
                SettingsChangeCellContent(transaction: settingChange!)
            } else if masterCopy != nil {
                ChangeMasterCopyCellContent(transaction: masterCopy!)
            } else {
                EmptyView()
            }
        }
    }
}
