//
//  OwnerChangeTransactionHeaderView.swift
//  Multisig
//
//  Created by Moaaz on 6/16/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SettingsChangeTransactionDetailsHeaderView: View {
    let transaction: SettingChangeTransactionViewModel

    var body: some View {
        VStack (alignment: .leading, spacing: 11) {
            contentView
        }
    }

    var contentView: some View {
        let addOwnerWithThreshold = transaction.info as? AddOwnerSettingsChangeTransactionSummaryInfo
        let removeOwner = transaction.info as? RemoveOwnerSettingsChangeTransactionSummaryInfo
        let swapOwner = transaction.info as? SwapOwnerSettingsChangeTransactionSummaryInfo
        let setFallbackHandler = transaction.info as? SetFallbackHandlerSettingsChangeTransactionSummaryInfo
        let enableModule = transaction.info as? EnableModuleSettingsChangeTransactionSummaryInfo
        let disableModule = transaction.info as? DisableModuleSettingsChangeTransactionSummaryInfo
        let changeThreshold = transaction.info as? ChangeThresholdSettingsChangeTransactionSummaryInfo

        return ZStack {
            if addOwnerWithThreshold != nil {
                AddRemoveOwnerTransactionDetailsHeaderView(state: .add, address: addOwnerWithThreshold!.owner.address, threshold: addOwnerWithThreshold!.threshold)
            } else if removeOwner != nil {
                AddRemoveOwnerTransactionDetailsHeaderView(state: .remove, address: removeOwner!.owner.address, threshold: removeOwner!.threshold)
            } else if swapOwner != nil {
                SwapOwnerTransactionDetailsHeaderView(removedAddress: swapOwner!.oldOwner.address, addedAddress: swapOwner!.newOwner.address)
            } else if setFallbackHandler != nil {
                SetFallbackHandlerTransactionDetailsHeaderView(address: setFallbackHandler!.handler.address)
            } else if enableModule != nil {
                EnableDisableModuleTransactionDetailsHeaderView(state: .enable, address: enableModule!.module.address)
            } else if disableModule != nil {
                EnableDisableModuleTransactionDetailsHeaderView(state: .disable, address: disableModule!.module.address)
            } else if changeThreshold != nil {
                ChangeThresholdTransactionDetailsHeaderView(threshold: changeThreshold!.threshold)
            } else {
                EmptyView()
            }
        }
    }
}
