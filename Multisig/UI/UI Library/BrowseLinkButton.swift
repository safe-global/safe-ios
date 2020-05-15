//
//  BrowseLinkButton.swift
//  Multisig
//
//  Created by Moaaz on 5/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BrowseLinkButton: View {
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
                
                BodyText(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Font.footnote.bold())
                    .foregroundColor(Color.systemGray6Light)
            }
        }
        .sheet(isPresented: $showsLink, content: browseSafeAddress)
    }

    func browseSafeAddress() -> some View {
        return SafariViewController(url: url)
    }
}

struct BrowseLinkButton_Previews: PreviewProvider {
    static var previews: some View {
        BrowseLinkButton(title: "test", url: URL(string:"www.google.com")!)
    }
}

