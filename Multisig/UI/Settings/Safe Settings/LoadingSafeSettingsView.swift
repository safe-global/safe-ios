//
//  LoadingSafeSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeSettingsContent: View {
    var body: some View {
        // so it does not jump when switching Assets <-> Settings in the tap bar
        WhenSafeSelected(padding: (.top, -56), noSafeEvent: .settingsSafeNoSafe) {
            LoadingSafeSettingsView()
                .fullScreenBackground()
        }
    }
}

struct LoadingSafeSettingsView: View {
    @EnvironmentObject var model: LoadingSafeSettingsViewModel

    var body: some View {
        NetworkContentView(status: model.status, reload: model.reload) {
            SafeSettingListView(safe: $model.safe, reload: model.reload)
        }
    }
}

struct SafeSettingListView: View {
    @Binding var safe: Safe!
    var reload: () -> Void = {}

    let rowHeight: CGFloat = 48

    var body: some View {
        if safe == nil {
            Text("Loading...")
        } else {
            List {
                ReloadButton(reload: reload)
                SafeName(safe: safe, rowHeight: rowHeight)
                Confirmations(safe: safe, rowHeight: rowHeight)
                OwnerAddress(safe: safe)
                ContractVersion(safe: safe)
                ENSName(safe: safe, rowHeight: rowHeight)
                Advanced(safe: safe, rowHeight: rowHeight)
            }
            .listStyle(GroupedListStyle())
        }
    }
}

extension SafeSettingListView {

    struct SafeName: View {
        var safe: Safe
        var rowHeight: CGFloat

        var body: some View {
            Section(header: SectionHeader("SAFE NAME")) {
                NavigationLink(
                    destination:
                        EditSafeNameView(
                            address: safe.address ?? "",
                            name: safe.name ?? ""),
                    label: {
                        Text(safe.name ?? "").body()
                    })
                    .frame(height: rowHeight)
            }
        }
    }

    struct Confirmations: View {
        var safe: Safe
        var rowHeight: CGFloat

        var body: some View {
            Section(header: SectionHeader("REQUIRED CONFIRMATIONS")) {
                Text("\(String(describing: safe.threshold ?? 0)) out of \(safe.owners?.count ?? 0)")
                    .body()
                    .frame(height: rowHeight)
            }
        }
    }

    struct OwnerAddress: View {
        var safe: Safe
        var body: some View {
            Section(header: SectionHeader("OWNER ADDRESSES")) {
                ForEach(safe.owners ?? [], id: \.self, content: { owner in
                    AddressCell(address: owner.checksummed)
                })
            }
        }
    }

    struct ContractVersion: View {
        var safe: Safe

        var body: some View {
            Section(header: SectionHeader("CONTRACT VERSION")) {
                ContractVersionCell(implementation: safe.implementation?.checksummed)
            }
        }
    }

    struct ENSName: View {
        var safe: Safe
        var rowHeight: CGFloat

        var body: some View {
            Section(header: SectionHeader("ENS NAME")) {
                LoadableENSNameText(safe: safe, placeholder: "Reverse record not set")
                    .frame(height: rowHeight)
            }
        }
    }

    struct Advanced: View {
        var safe: Safe
        var rowHeight: CGFloat

        var body: some View {
            Section(header: SectionHeader("")) {
                NavigationLink(destination: AdvancedSafeSettingsView(safe: safe)) {
                    Text("Advanced").body()
                }
                .frame(height: rowHeight)

                RemoveSafeButton(safe: self.safe)
            }
        }
    }
}
