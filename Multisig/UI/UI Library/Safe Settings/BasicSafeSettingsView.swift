//
//  BasicSafeSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BasicSafeSettingsView: View {

    @ObservedObject
    var safe: Safe

    let rowHeight: CGFloat = 48
    
    var body: some View {
        List {
            Section(header: SectionHeader("SAFE NAME")) {
                NavigationLink(destination: EditSafeNameView(address: safe.address ?? "", name: safe.name ?? "")) {
                    BodyText(safe.name ?? "")
                }
                .frame(height: rowHeight)
            }

            Section(header: SectionHeader("REQUIRED CONFIRMATIONS")) {
                BodyText("\(safe.threshold ?? 0) out of \(safe.owners?.count ?? 0)")
                    .frame(height: rowHeight)
            }

            Section(header: SectionHeader("OWNER ADDRESSES")) {
                ForEach(safe.owners ?? [], id: \.self, content: { owner in
                    AddressCell(address: owner)
                })
            }

            Section(header: SectionHeader("CONTRACT VERSION")) {
                ContractVersionCell(address: safe.masterCopy ?? "", version: safe.version ?? "")
            }

            Section(header: SectionHeader("ENS NAME")) {
                LoadableENSNameText(safe: safe, placeholder: "Not set")
                    .frame(height: rowHeight)
            }

            Section(header: SectionHeader(" ")) {
                NavigationLink(destination: AdvancedSafeSettingsView(safe: safe)) {
                    BodyText("Advanced")
                }
                .frame(height: rowHeight)
                
				RemoveSafeButton(safe: self.safe)
            }
        }
    }
}

struct BasicSafeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicSafeSettingsView(safe: Safe())
    }
}
