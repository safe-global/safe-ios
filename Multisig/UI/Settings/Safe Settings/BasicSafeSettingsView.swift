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
                NavigationLink(destination:
                    EditSafeNameView(
                        address: safe.address ?? "",
                        name: safe.name ?? ""
                    )
                    .hidesSystemNavigationBar(false)) {
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
                    AddressCell(address: owner.checksummed)
                })
            }

            Section(header: SectionHeader("CONTRACT VERSION")) {
                ContractVersionCell(masterCopy: safe.masterCopy?.checksummed)
            }

            Section(header: SectionHeader("ENS NAME")) {
                LoadableENSNameText(safe: safe, placeholder: "Reverse record not set")
                    .frame(height: rowHeight)
            }

            Section(header: SectionHeader("")) {
                NavigationLink(destination: AdvancedSafeSettingsView(safe: safe).hidesSystemNavigationBar(false)) {
                    BodyText("Advanced")
                }
                .frame(height: rowHeight)

				RemoveSafeButton(safe: self.safe)
            }
        }
        .onAppear {
            self.trackEvent(.settingsSafe)
        }
    }
}

struct BasicSafeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicSafeSettingsView(safe: Safe())
    }
}
