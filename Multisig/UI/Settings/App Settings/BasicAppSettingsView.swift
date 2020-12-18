//
//  AppSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BasicAppSettingsView: View {
    var rowHeight: CGFloat = 44

    private let legal = App.configuration.legal
    private let app = App.configuration.app

    @ObservedObject
    var appSettings = App.shared.settings

    @State
    var showDeleteSigningKeyConfirmation: Bool = false

    var signingKeyAddress: String? {
        return appSettings.signingKeyAddress
    }

    var body: some View {
        List {
            if App.configuration.toggles.signing {
                signingWalletView
            }

            BrowserLink(title: "Terms of use", url: legal.termsURL)

            BrowserLink(title: "Privacy policy", url: legal.privacyURL)

            BrowserLink(title: "Licenses", url: legal.licensesURL)

            NavigationLink(destination: GetInTouchView()) {
                Text("Get in touch").body()
            }
            .frame(height: rowHeight)
            
            KeyValueView(key: "App version",
                         value:"\(app.marketingVersion) (\(app.buildVersion))")

            KeyValueView(key: "Network", value: app.network.rawValue)

            Section(header: SectionHeader("")) {
                NavigationLink(destination: AdvancedAppSettings()) {
                    Text("Advanced").body()
                }
                .frame(height: rowHeight)
            }
        }
        .background(
            Rectangle()
                .edgesIgnoringSafeArea(.all)
                .foregroundColor(Color.gnoWhite)
        )
        .onAppear {
            self.trackEvent(.settingsApp)
        }
    }

    @ViewBuilder
    var signingWalletView: some View {
        if signingKeyAddress != nil {
            HStack {
                AddressCell(address: signingKeyAddress!,
                            title: "Imported owner key",
                            style: .shortAddressNoShareGrayColor)
                Spacer()
                Button(action: {
                    showDeleteSigningKeyConfirmation.toggle()
                }, label: {
                    Image(systemName: "trash").font(.gnoBody).foregroundColor(.gnoTomato)
                })
                .actionSheet(isPresented: $showDeleteSigningKeyConfirmation) {
                    ActionSheet(
                        title: Text(""),
                        message: Text("Removing the owner key only removes it from this app. It doesn't delete any Safes from this app or from blockchain. For Safes controlled by this owner key, you will no longer be able to sign transactions in this app"),
                        buttons: [
                            .destructive(Text("Remove")) {
                                do {
                                    try App.shared.keychainService.removeData(
                                        forKey: KeychainKey.ownerPrivateKey.rawValue)
                                    App.shared.settings.updateSigningKeyAddress()                                    
                                    App.shared.snackbar.show(message: "Owner key removed from this app")
                                    Tracker.shared.setNumKeysImported(0)
                                } catch {
                                    App.shared.snackbar.show(message: error.localizedDescription)
                                }
                            },
                            .cancel()
                        ])
                }
            }
        } else {
            Button {
                App.shared.viewState.showImportKeySheet.toggle()
            } label: {
                HStack {
                    Text("Import owner key").body()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Font.footnote.bold())
                        .foregroundColor(Color.systemGray6Light)
                }
            }
        }
    }
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
