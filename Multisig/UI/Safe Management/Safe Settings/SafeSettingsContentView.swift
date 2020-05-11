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

    @State
    var showDeleteConfirmation: Bool = false
    
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
                Button(action: {
                    self.showDeleteConfirmation.toggle()
                }) {
                    HStack {
                        Image("ico-remove")
                        Text("Remove Safe").font(.gnoHeadline)
                        Spacer()
                    }
                    .padding()
                }
                .foregroundColor(Color.gnoTomato)
                .buttonStyle(BorderlessButtonStyle())
                .background(Color.gnoWhite)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .actionSheet(isPresented: $showDeleteConfirmation) {
                    ActionSheet(title: Text(""), message: Text("Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost."), buttons: [
                        .destructive(Text("Remove")) {
                            Safe.delete()
                        },
                        .cancel()
                    ])
                }
            }
        }
    }
}

struct SafeSettingsContentView_Previews: PreviewProvider {
    static var previews: some View {
        SafeSettingsContentView(safe: Safe())
    }
}
