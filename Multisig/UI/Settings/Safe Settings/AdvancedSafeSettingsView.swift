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
                BodyText("\(safe.nonce ?? 0)")
            }
             
            modulesSection
        
        }
        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
            self.trackEvent(.settingsSafeAdvanced)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        let fallbackHandler = safe.fallbackHandler ?? ""
        let title = safe.isDefaultFallbackHandler() ? "DefaultFallbackHandler" : "Unknown"
        return Group {
            if fallbackHandler.isEmpty || fallbackHandler == "0" {
                 BodyText("Not set")
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
                        AddressCell(address: owner, style: .shortAddress)
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
