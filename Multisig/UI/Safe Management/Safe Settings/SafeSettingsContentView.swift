//
//  SafeSettingsContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeSettingsContentView: View {

    @ObservedObject
    var safe: Safe
    
    var body: some View {
        List {
            Section(header: ListSectionHeader(text:"SAFE NAME")) {
                NavigationLink(destination: EditSafeNameView(address: safe.address ?? "", name: safe.name ?? "")) {
                    BodyText(safe.name ?? "")
                }
            }

            Section(header: ListSectionHeader(text: "REQUIRED CONFIRMATIONS")) {
                BodyText("\(safe.threshold ?? 0) out of \(safe.owners?.count ?? 0)")
            }

            Section(header: ListSectionHeader(text: "OWNER ADDRESSES")) {
                ForEach(safe.owners ?? [], id: \.self, content: { owner in
                    AddressCell(address: owner)
                })
            }

            Section(header: ListSectionHeader(text: "CONTRACT VERSION")) {
                ContractVersionCell(address: safe.masterCopy ?? "", version: safe.version ?? "")
            }

            Section(header: ListSectionHeader(text: "ENS NAME")) {
                LoadableENSNameText(safe: safe, placeholder: "Not Set")
            }

            Section(header: ListSectionHeader(text: " ")) {
                NavigationLink(destination: SafeAdvancedSettingsView(safe: safe)) {
                    BodyText("Advanced")
                }
            }
            
            Section(header: ListSectionHeader(text: " ")) {
                RemoveSafeButton(safe: self.safe)
            }
        }
    }
}

struct SafeSettingsContentView_Previews: PreviewProvider {
    static var previews: some View {
        SafeSettingsContentView(safe: Safe())
    }
}
