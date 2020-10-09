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
            self.trackEvent(.settingsSafeAdvanced)
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        let title = App.shared.gnosisSafe.fallbackHandlerLabel(fallbackHandler: safe.fallbackHandler)
        return Section(header: SectionHeader("FALLBACK HANDLER")) {
            if App.shared.gnosisSafe.hasFallbackHandler(safe: safe) {
                AddressCell(address: safe.fallbackHandler!.checksummed, title: title, style: .shortAddress)
            } else {
                Text("Not set").body()
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
                        AddressCell(address: owner.checksummed, title: "Unknown", style: .shortAddress)
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
