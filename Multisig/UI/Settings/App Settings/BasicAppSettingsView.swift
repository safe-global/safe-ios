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

    @State
    var addOwnerIsActive = false

    var body: some View {
        List {
            ForEach(0..<1) { _ in
                NavigationLink(destination: EnterSeedPhraseView(rootIsActive: self.$addOwnerIsActive),
                               isActive: self.$addOwnerIsActive) {
                    Text("Import owner wallet").body()
                }
                .isDetailLink(false)
            }
            .onDelete { _ in
                // Do nothing for now
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
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
