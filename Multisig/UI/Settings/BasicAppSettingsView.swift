//
//  AppSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BasicAppSettingsView: View {
    var rowHeight: CGFloat = 60

    var body: some View {
        List {
            NavigationLink(destination: FiatCurrenciesView()) {
                keyValueView(key: "Fiat currency", value: "EUR")
            }
            .frame(height: rowHeight)

            BrowseLinkButton(title: "Terms of use", url: App.shared.termOfUseURL)
               .frame(height: rowHeight)

            BrowseLinkButton(title: "Privacy policy", url: App.shared.privacyPolicyURL)
               .frame(height: rowHeight)

            BrowseLinkButton(title: "Licenses", url: App.shared.licensesURL)
               .frame(height: rowHeight)

            NavigationLink("Get in touch", destination: GetInTouchView())
                .frame(height: rowHeight)

            keyValueView(key: "App version", value: App.shared.appVersion)

            keyValueView(key: "Network", value: App.shared.network.rawValue)

            Section(header: SectionHeader(" ")) {
                NavigationLink(destination: AdvancedAppSettings()) {
                    BodyText("Advanced")
                }
                .frame(height: rowHeight)
            }
        }
    }
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
