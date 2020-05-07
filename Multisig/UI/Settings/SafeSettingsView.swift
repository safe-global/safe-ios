//
//  SafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeSettingsView: View {

    @ObservedObject
    var model = SafeSettingsViewModel()

    @ObservedObject
    var safe: Safe
    
    /// when change safe, model object should be changed also 
    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading ?? false {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            }
            else {
                List {
                    Section(header: ListSectionHeader(text:"SAFE NAME")) {
                        NavigationLink(destination: EditSafeNameView(address: safe.address ?? "", name: safe.name ?? "")) {
                            BodyText(safe.name ?? "")
                        }
                    }
                    
                    Section(header: ListSectionHeader(text: "REQUIRED CONFIRMATIONS")) {
                        BodyText("\(model.info?.threshold ?? 0) out of \(model.info?.owners.count ?? 0)")
                    }
                    
                    Section(header: ListSectionHeader(text: "OWNER ADDRESSES")) {
                        ForEach(model.info?.owners ?? [], id: \.self, content: { owner in
                            AddressCell(address: owner)
                        })
                    }
                    
                    Section(header: ListSectionHeader(text: "CONTRACT VERSION")) {
                        ContractVersionCell(address: safe.address ?? "", version: model.info?.version ?? "")
                    }
                    
                    Section(header: ListSectionHeader(text: "ENS NAME")) {
                        LoadableENSNameText(safe: safe, placeholder: "Not Set")
                    }
                    
                    Section(header: ListSectionHeader(text: " ")) {
                        NavigationLink(destination: SafeAdvancedSettingsView(safe: safe,model: model)) {
                            BodyText("Advanced")
                        }
                    }
                }
            }
        }.onAppear(perform: {
            if self.model.info == nil && !(self.model.isLoading ?? false) {
                self.model.address = self.safe.address ?? ""
                self.model.load()
            }
        })
    }
    
    
}
