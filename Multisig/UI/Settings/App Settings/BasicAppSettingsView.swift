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

    var body: some View {
        List {
            NavigationLink(destination: FiatCurrenciesView().hidesSystemNavigationBar(false)) {
                KeyValueView(key: "Fiat currency", value: "USD")
            }
            .frame(height: rowHeight)

            BrowserLink(title: "Terms of use", url: App.shared.termOfUseURL)

            BrowserLink(title: "Privacy policy", url: App.shared.privacyPolicyURL)

            BrowserLink(title: "Licenses", url: App.shared.licensesURL)

            NavigationLink(destination: GetInTouchView().hidesSystemNavigationBar(false)) {
                BodyText("Get in touch")
            }
            .frame(height: rowHeight)
            
            KeyValueView(key: "App version", value: App.shared.appVersion)

            KeyValueView(key: "Network", value: App.shared.network.rawValue)

            Section(header: SectionHeader(" ")) {
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
    }
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
