//
//  GetInTouchView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GetInTouchView: View {

    typealias CommsChannel = (url: URL, icon: String, text: String)

    @ObservedObject
    var theme: Theme = App.shared.theme

    private static let contact = App.configuration.contact

    
    let channels: [CommsChannel] = [
        (contact.discordURL, "ico-discord", "Discord"),
        (contact.twitterURL, "ico-twitter", "Twitter"),
        (contact.helpCenterURL, "ico-helpCenter", "Help Center"),
        (contact.featureSuggestionURL, "ico-featureSuggestion", "Feature suggestion")
    ]

    var body: some View {
        List {
            EmailLink(title: "E-mail", url: Self.contact.contactEmail, iconName: "ico-eMail")

            ForEach(channels, id: \.url) { item in
                BrowserLink(title: item.text, url: item.url, iconName: item.icon)
            }
        }
        .onAppear {
            Tracker.trackEvent(.settingsAppSupport)
        }
        .navigationBarTitle("Help Center", displayMode: .inline)
    }
}

struct GetInTouchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GetInTouchView()
        }
    }
}
