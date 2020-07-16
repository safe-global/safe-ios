//
//  AdvancedSafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct AdvancedSafeSettingsView: View {

    @ObservedObject
    var safe: Safe

    @ObservedObject
    var theme: Theme = App.shared.theme
    
    var body: some View {
        List {
            fallbackHandlerView
            
            Section(header: SectionHeader("NONCE")) {
                Text("\(String(describing: safe.nonce ?? 0))").body()
            }
             
            modulesSection
        
        }
        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
            self.theme.resetRowsSelection()
            self.trackEvent(.settingsSafeAdvanced)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        let fallbackHandler = safe.fallbackHandler?.checksummed ?? ""
        let title = App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: safe.fallbackHandler)
        return Group {
            if fallbackHandler.isEmpty || fallbackHandler == "0" {
                 Text("Not set").body()
            } else {
                Section(header: SectionHeader("FALLBACK HANDLER")) {
                    AddressCell(address: fallbackHandler, title: title, style: .shortAddress)
                }
            }
        }
    }
    
    var modulesSection: some View {
        Group {
            if (safe.modules ?? []).isEmpty {
                 EmptyView()
            } else {
                Section(header: SectionHeader("ADDRESSES OF ENABLED MODULES")) {
                    ForEach(safe.modules ?? [], id: \.self, content: { owner in
                        AddressCell(address: owner.checksummed, style: .shortAddress)
                    })
                }
            }
        }
    }
}

struct SafeAdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSafeSettingsView(safe: Safe())
    }
}
