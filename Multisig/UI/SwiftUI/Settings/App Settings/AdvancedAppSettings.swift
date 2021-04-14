//
//  AdvancedAppSettings.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AdvancedAppSettings: View {

    @ObservedObject
    var theme: Theme = App.shared.theme

    var body: some View {
        List {
            Section(header: SectionHeader("ENS RESOLVER ADDRESS")) {
                AddressCell(address: App.shared.ens.registryAddress.checksummed)
            }

            Section(header: SectionHeader("ENDPOINTS")) {
                KeyValueRow("RPC endpoint",
                            value: DisplayURL(App.shared.nodeService.url).absoluteString)
                KeyValueRow("Transaction service",
                            value: DisplayURL(App.shared.safeTransactionService.url).absoluteString)
                KeyValueRow("Client Gateway service",
                            value: DisplayURL(App.shared.clientGatewayService.url).absoluteString)
            }

            Section(header: SectionHeader("TRACKING")) {
                ToggleTrackingRow()
            }

            if !(App.configuration.services.environment == .production) {
                Section(header: SectionHeader("DEBUG")) {
                    Button(action: {
                        fatalError()
                    }) {
                        Text("Crash the App").body()
                    }
                }
            }
        }
        .onAppear {
            self.trackEvent(.settingsAppAdvanced)
        }
        .navigationBarTitle("Advanced", displayMode: .inline)
    }

    struct ToggleTrackingRow: View {
        @State
        var trackingEnabled = AppSettings.trackingEnabled

        var body: some View {
            Toggle(isOn: $trackingEnabled.didSet { enabled in
                AppSettings.trackingEnabled = enabled
            }) {
                Text("Share Usage Data").headline()
            }
        }
    }
}

/// https://stackoverflow.com/questions/56996272/how-can-i-trigger-an-action-when-a-swiftui-toggle-is-toggled
fileprivate extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

struct AdvancedAppSettings_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedAppSettings()
    }
}
