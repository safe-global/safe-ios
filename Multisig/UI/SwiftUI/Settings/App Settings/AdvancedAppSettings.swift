//
//  AdvancedAppSettings.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import AppTrackingTransparency

struct AdvancedAppSettings: View {

    @ObservedObject
    var theme: Theme = App.shared.theme

    var body: some View {
        List {
            Section(header: SectionHeader("ENS RESOLVER ADDRESS")) {
                AddressCell(address: App.shared.blockchainDomainManager.ens.registryAddress.checksummed)
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

            DataSharingInfo()

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
        private var trackingEnabled = AppSettings.trackingEnabled

        @State
        private var showingSettingsAlert = false

        var body: some View {
            VStack {
                Toggle(isOn: $trackingEnabled.didSet { enabled in
                    if #available(iOS 14, *) {

                        switch ATTrackingManager.trackingAuthorizationStatus {
                        case .notDetermined:
                            ATTrackingManager.requestTrackingAuthorization { status in
                                switch status {
                                case .authorized:
                                    AppSettings.trackingEnabled = true
                                    trackingEnabled = true
                                case .denied, .notDetermined, .restricted:
                                    AppSettings.trackingEnabled = false
                                    trackingEnabled = false
                                @unknown default:
                                    AppSettings.trackingEnabled = false
                                    trackingEnabled = false
                                }
                            }
                            return

                        case .authorized:
                            AppSettings.trackingEnabled = enabled

                        case .denied, .restricted:
                            showingSettingsAlert = true

                        @unknown default:
                            showingSettingsAlert = true
                        }

                    } else /* !#available(iOS 14, *) */ {
                        AppSettings.trackingEnabled = enabled
                    }
                }) {
                    Text("Share Usage and Crash Data").headline()
                }
                .frame(height: 60)
            }
            .alert(isPresented: $showingSettingsAlert) {
                Alert(title: Text("Please allow tracking in Settings"),
                      message: Text("Currently tracking is disabled for the app."),
                      primaryButton: .cancel {
                        trackingEnabled = false
                      },
                      secondaryButton: .default(Text("Settings")) {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        trackingEnabled = true
                      })
            }
        }
    }

    struct DataSharingInfo: View {
        var body: some View {
            VStack {
                Text("By sharing usage data with Gnosis, you are helping us improve the app with anonymized app usage data")
                    .body(.gray)
                HStack {
                    BrowseLinkButton(title: "What data is shared?", url: App.configuration.legal.privacyURL)
                    Spacer()
                }
            }
            .padding()
            .background(Color.primaryBackground)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
