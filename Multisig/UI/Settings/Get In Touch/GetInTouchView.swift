//
//  GetInTouchView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GetInTouchView: View {

    typealias CommsChannel = (url: String, icon: String, text: String)

    let channels: [CommsChannel] = [
        ("safe@gnosis.io", "ico-eMail", "E-mail"),
        ("https://discord.gg/FPMRAwK", "ico-discord", "Discord"),
        ("https://twitter.com/gnosisSafe", "ico-twitter", "Twitter"),
        ("https://help.gnosis-safe.io", "ico-helpCenter", "Help Center"),
        ("https://safe.cnflx.io/", "ico-featureSuggestion", "Feature suggestion")
    ]

    // we have a trigger value for each type of a sheet or alert.
    // when these values become non-nil, the respective sheet or alert sheet
    // will be opened.
    @State var emailURL: IdentifiableByHash<URL>?
    @State var browserURL: IdentifiableByHash<URL>?
    @State var error: IdentifiableByHash<String>?

    var body: some View {
        List {
            ForEach(channels, id: \.url) { item in
                Button(action: { self.updateActiveURL(item: item) }) {
                    HStack {
                        Image(item.icon)
                        BodyText(item.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.gnoDarkGrey)
                    }
                }
                .frame(height: 60)

            }
            // to make bottom separator on the last row
            HStack {
                // workaround to enable multiple sheet modifiers work
                // otherwise only the last sheet modifier is working if
                // all of them attached to the same view.
                Text("").sheet(item: $emailURL) { url in
                    EmailSupportViewController(url: url.value)
                }

                Text("").alert(item: $error) { msg in
                    Alert(title: Text(msg.value))
                }

                Text("").sheet(item: $browserURL) { url in
                    SafariViewController(url: url.value)
                }
            }
        }
        .navigationBarTitle("Get In Touch", displayMode: .inline)
    }

    func updateActiveURL(item: CommsChannel) {
        emailURL = nil
        browserURL = nil
        error = nil

        guard let url = URL(string: item.url) else { return }

        if url.absoluteString.contains("@") {
            if EmailSupportViewController.isAvailable {
                emailURL = IdentifiableByHash(url)
            } else {
                error = IdentifiableByHash("Mail is not configured.")
            }
        } else {
            browserURL = IdentifiableByHash(url)
        }
    }
}

struct GetInTouchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GetInTouchView()
        }
    }
}
