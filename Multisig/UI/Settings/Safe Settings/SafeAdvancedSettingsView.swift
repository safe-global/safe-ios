//
//  SafeAdvancedSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeAdvancedSettingsView: View {

    @ObservedObject
    var safe: Safe

    var body: some View {
        List {
            Section(header: ListSectionHeader(text: "MASTER COPY ADDRESS")) {
                AddressCell(address: safe.masterCopy ?? "-")
            }
            
            fallbackHandlerView
            
            Section(header: ListSectionHeader(text: "NONCE")) {
                BodyText("\(safe.nonce ?? 0)")
            }
             
            modulesSection
        
        }.navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        Group {
            if (safe.fallbackHandler ?? "").isEmpty  {
                 EmptyView()
            } else {
                Section(header: ListSectionHeader(text:"FALLBACK HANDLER")) {
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
                Section(header: ListSectionHeader(text: "ADDRESSES OF ENABLED MODULES")) {
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
        SafeAdvancedSettingsView(safe: Safe())
    }
}
