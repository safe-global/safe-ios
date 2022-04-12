//
//  BrowseLinkButton.swift
//  Multisig
//
//  Created by Moaaz on 7/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BrowseLinkButton: View {
    let title: String
    let url: URL

    @State
    private var showsLink: Bool = false

    var body: some View {
        Button(action: { self.showsLink.toggle() }) {
            LinkText(title: title)
        }
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.primary)
        .sheet(isPresented: $showsLink, content:  browseTransaction)
    }

    func browseTransaction() -> some View {
        return SafariViewController(url: url)
    }
}

struct BrowseLinkButton_Previews: PreviewProvider {
    static var previews: some View {
        BrowseLinkButton(title: "View on google", url: URL(string: "www.google.com")!)
    }
}
