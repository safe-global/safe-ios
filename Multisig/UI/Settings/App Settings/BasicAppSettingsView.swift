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

    @FetchRequest(fetchRequest: AppSettings.fetchRequest().all())
    var appSettings: FetchedResults<AppSettings>

    var signingKeyAddress: String? {
        return appSettings.first?.signingKeyAddress
    }

    @State
    var addOwnerIsActive = false

    var body: some View {
        List {
//            if signingKeyAddress != nil {
//                ForEach(0..<1) { _ in
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Signing key").bold()
//                        AddressView(self.signingKeyAddress!)
//                    }
//                    .padding()
//                }
//                .onDelete { _ in
//                    do {
//                        try App.shared.keychainService.removeData(forKey: KeychainKey.ownerPrivateKey.rawValue)
//                        AppSettings.setSigningKeyAddress(nil)
//                    } catch {
//                        App.shared.snackbar.show(message: error.localizedDescription)
//                    }
//                }
//            } else {
//                NavigationLink(destination: EnterSeedPhraseView(rootIsActive: self.$addOwnerIsActive),
//                               isActive: self.$addOwnerIsActive) {
//                                Text("Import signing key").body()
//                }
//                .isDetailLink(false)
//            }

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
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
