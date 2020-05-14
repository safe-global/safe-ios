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

    var rowHeight: CGFloat = 48
    
    var body: some View {
        List {
            Section(header: ListSectionHeader(text:"SAFE NAME")) {
                NavigationLink(destination: EditSafeNameView(address: safe.address ?? "", name: safe.name ?? "")) {
                    BodyText(safe.name ?? "")
                }
                .frame(height: rowHeight)
            }

            Section(header: ListSectionHeader(text: "REQUIRED CONFIRMATIONS")) {
                BodyText("\(safe.threshold ?? 0) out of \(safe.owners?.count ?? 0)")
                    .frame(height: rowHeight)
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
                LoadableENSNameText(safe: safe, placeholder: "Not set")
                    .frame(height: rowHeight)
            }

            Section(header: ListSectionHeader(text: " ")) {
                NavigationLink(destination: SafeAdvancedSettingsView(safe: safe)) {
                    BodyText("Advanced")
                }
                .frame(height: rowHeight)
                
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
