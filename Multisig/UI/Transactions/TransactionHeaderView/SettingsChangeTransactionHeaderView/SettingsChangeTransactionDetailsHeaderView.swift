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
        let addOwnerWithThreshold = transaction.method as? MethodRegistry.GnosisSafeSettings.AddOwnerWithThreshold
        let removeOwner = transaction.method as? MethodRegistry.GnosisSafeSettings.RemoveOwner
        let swapOwner = transaction.method as? MethodRegistry.GnosisSafeSettings.SwapOwner
        let setFallbackHandler = transaction.method as? MethodRegistry.GnosisSafeSettings.SetFallbackHandler
        let enableModule = transaction.method as? MethodRegistry.GnosisSafeSettings.EnableModule
        let disableModule = transaction.method as? MethodRegistry.GnosisSafeSettings.DisableModule
        let changeThreshold = transaction.method as? MethodRegistry.GnosisSafeSettings.ChangeThreshold

        return ZStack {
            if addOwnerWithThreshold != nil {
                AddRemoveOwnerTransactionDetailsHeaderView(state: .add, address: addOwnerWithThreshold!.address, threshold: addOwnerWithThreshold!.threshold)
            } else if removeOwner != nil {
                AddRemoveOwnerTransactionDetailsHeaderView(state: .remove, address: removeOwner!.prevOwner, threshold: removeOwner!.threshold)
            } else if swapOwner != nil {
                SwapOwnerTransactionDetailsHeaderView(removedAddress: swapOwner!.prevOwner, addedAddress: swapOwner!.newOwner)
            } else if setFallbackHandler != nil {
                SetFallbackHandlerTransactionDetailsHeaderView(address: setFallbackHandler!.handler)
            } else if enableModule != nil {
                EnableDisableModuleTransactionDetailsHeaderView(state: .enable, address: enableModule!.module)
            } else if disableModule != nil {
                EnableDisableModuleTransactionDetailsHeaderView(state: .disable, address: disableModule!.module)
            }
            else if changeThreshold != nil {
                ChangeThresholdTransactionDetailsHeaderView(threshold: changeThreshold!.threshold)
            }
            else {
                EmptyView()
            }
        }
    }
}
