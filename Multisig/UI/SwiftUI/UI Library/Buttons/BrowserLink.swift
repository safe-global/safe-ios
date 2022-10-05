//
//  BrowseLinkButton.swift
//  Multisig
//
//  Created by Moaaz on 5/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BrowserLink: View {
    @State
    private var showsLink: Bool = false

    var title: String
    var url: URL
    var iconName: String?

    var body: some View {
        Button(action: {
            self.showsLink.toggle()
        }) {
            HStack {
                if iconName != nil {
                    Image(iconName!)
                }
                
                Text(title).body()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Font.footnote.bold())
                    .foregroundColor(.backgroundSecondary)
            }
        }
        .frame(height: 44)
        .sheet(isPresented: $showsLink, content: {
            SafariViewController(url: self.url)
        })
    }
}

struct BrowserLink_Previews: PreviewProvider {
    static var previews: some View {
        BrowserLink(title: "test", url: URL(string:"www.google.com")!)
    }
}

