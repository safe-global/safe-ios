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
    let safe: Safe?
    let model: SafeSettingsViewModel?
    var body: some View {
        List {
            Section(header: ListSectionHeader(text: "MASTER COPY ADDRESS")) {
                AddressCell(address: model?.info?.masterCopy ?? "-")
            }
            
            fallbackHandlerView
            
            Section(header: ListSectionHeader(text: "NONCE")) {
                BodyText("\(model?.info?.nonce ?? 0)")
            }
             
            modulesSection
        
        }.navigationBarTitle("Advanced", displayMode: .inline)
    }
    
    var fallbackHandlerView : some View {
        Group {
            if (model?.info?.fallbackHandler ?? "").isEmpty  {
                 EmptyView()
            }
            else {
                Section(header: ListSectionHeader(text:"FALLBACK HANDLER")) {
                    AddressCell(address: model?.info?.fallbackHandler ?? "Not Set")
                }
            }
        }
    }
    
    var modulesSection: some View {
        Group {
            if (model?.info?.modules ?? []).isEmpty {
                 EmptyView()
            }
            else {
                Section(header: ListSectionHeader(text: "ADDRESSES OF ENABLED MODULES")) {
                    ForEach(model?.info?.modules ?? [], id: \.self, content: { owner in
                        AddressCell(address: owner)
                    })
                }
            }
        }
    }
}

struct SafeAdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SafeAdvancedSettingsView(safe: nil, model: nil)
    }
}
