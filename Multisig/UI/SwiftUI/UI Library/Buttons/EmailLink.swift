//
//  EmailLinkButton.swift
//  Multisig
//
//  Created by Moaaz on 5/18/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EmailLink: View {
    @State
    private var showsLink: Bool = false

    @State
    var error: IdentifiableByHash<String>?

    var title: String
    var url: URL
    var iconName: String?

    var body: some View {
        Button(action: {
            if EmailSupportViewController.isAvailable {
                self.showsLink.toggle()
            } else {
                self.error = IdentifiableByHash("Mail is not configured.")
            }
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
        .alert(item: $error) { msg in
            Alert(title: Text(msg.value))
        }
        .sheet(isPresented: $showsLink, content: {
            EmailSupportViewController(url: self.url)
        })

    }
}

struct EmailLink_Previews: PreviewProvider {
    static var previews: some View {
        EmailLink(title: "Email", url: URL(string: "support@safe.global")!)
    }
}
