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

    @State
    var activeURL: IdentifiableByHash<URL>?


    var body: some View {
        List {
            NavigationLink(destination: GetInTouchView()) {
                keyValueView(key: "Fiat currency", value: "test")
            }
            .frame(height: rowHeight)

            Button(action: {
                self.activeURL = IdentifiableByHash(App.shared.termOfUseURL)
            }) {
                   HStack {
                       BodyText("Term of use")
                       Spacer()
                       Image(systemName: "chevron.right")
                           .foregroundColor(Color.gnoLightGrey)
                   }
               }
               .frame(height: rowHeight)

            Button(action: {
                self.activeURL = IdentifiableByHash(App.shared.privacyPolicyURL)
            }) {
                   HStack {
                       BodyText("Privacy policy")
                       Spacer()
                       Image(systemName: "chevron.right")
                        .foregroundColor(Color.gnoLightGrey)
                   }
               }
               .frame(height: rowHeight)

            Button(action: {
                self.activeURL = IdentifiableByHash(App.shared.licensesURL)
            }) {
                   HStack {
                       BodyText("Licenses")
                       Spacer()
                       Image(systemName: "chevron.right")
                           .foregroundColor(Color.gnoLightGrey)
                   }
               }
               .frame(height: rowHeight)

            keyValueView(key: "App version", value: App.shared.appVersion)

            keyValueView(key: "Network", value: App.shared.network)

            Section(header: SectionHeader(" ")) {
                NavigationLink(destination: AdvancedAppSettings()) {
                    BodyText("Advanced")
                }
                .frame(height: rowHeight)
            }

        }.sheet(item: $activeURL, content: {_ in
            SafariViewController(url: self.activeURL!.value)
        })
    }
}

struct BasicSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BasicAppSettingsView()
    }
}
