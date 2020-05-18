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
    
    let channels: [CommsChannel] = [
        (URL(string:"https://discord.gg/FPMRAwK")!, "ico-discord", "Discord"),
        (URL(string:"https://twitter.com/gnosisSafe")!, "ico-twitter", "Twitter"),
        (URL(string:"https://help.gnosis-safe.io")!, "ico-helpCenter", "Help Center"),
        (URL(string:"https://safe.cnflx.io/")!, "ico-featureSuggestion", "Feature suggestion")
    ]

    var body: some View {
        List {
            EmailLink(title: "E-mail", url: URL(string:"safe@gnosis.io")!, iconName: "ico-eMail")

            ForEach(channels, id: \.url) { item in
                BrowserLink(title: item.text, url: item.url, iconName: item.icon)
            }
        }
        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
        .navigationBarTitle("Get In Touch", displayMode: .inline)
    }
}

struct GetInTouchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GetInTouchView()
        }
    }
}
