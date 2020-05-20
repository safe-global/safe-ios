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
            Section(header: SectionHeader("MASTER COPY ADDRESS")) {
                AddressCell(address: safe.masterCopy ?? "-")
            }
            
            fallbackHandlerView
            
            Section(header: SectionHeader("NONCE")) {
                BodyText("\(safe.nonce ?? 0)")
            }
             
            modulesSection
        
        }
        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        Group {
            if (safe.fallbackHandler ?? "").isEmpty  {
                 EmptyView()
            } else {
                Section(header: SectionHeader("FALLBACK HANDLER")) {
                    AddressCell(address: safe.fallbackHandler ?? "Not Set")
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
                        AddressCell(address: owner)
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
