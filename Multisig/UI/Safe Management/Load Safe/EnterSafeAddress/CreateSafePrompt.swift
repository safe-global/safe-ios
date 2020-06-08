//
//  CreateSafePrompt.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CreateSafePrompt: View {

    @State
    var showsLink: Bool = false

    var url: URL = App.configuration.services.webAppURL

    var body: some View {
        VStack(spacing: 0) {
            Text("Don't have a Safe? Create one first at")

            Button(action: { self.showsLink.toggle() }) {
                LinkText(title: url.absoluteString)
            }
        }
        .font(Font.gnoBody.weight(.medium))
        .foregroundColor(.gnoDarkBlue)
        .sheet(isPresented: $showsLink, content: browser)
    }

    func browser() -> some View {
        SafariViewController(url: url)
    }
}

struct CreateSafePrompt_Previews: PreviewProvider {
    static var previews: some View {
        CreateSafePrompt()
    }
}
