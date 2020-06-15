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

    var body: some View {
        List {
            BrowserLink(title: "Terms of use", url: legal.termsURL)

            BrowserLink(title: "Privacy policy", url: legal.privacyURL)

            BrowserLink(title: "Licenses", url: legal.licensesURL)

            NavigationLink(destination: GetInTouchView().hidesSystemNavigationBar(false)) {
                BodyText("Get in touch")
            }
            .frame(height: rowHeight)
            
            KeyValueView(key: "App version",
                         value:"\(app.marketingVersion) (\(app.buildVersion))"
)

            KeyValueView(key: "Network", value: app.network.rawValue)

            Section(header: SectionHeader("")) {
                NavigationLink(destination: AdvancedAppSettings().hidesSystemNavigationBar(false)) {
                    BodyText("Advanced")
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
//            self.trackEvent(.settingsApp)
        }
    }
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
