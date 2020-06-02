//
//  LinkButton.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct LinkButton: View {
    let name: String
    let url: URL

    @State private var showSafariController = false

    var body: some View {
        Button(action: {
            self.showSafariController = true
        }) {
            Text(name)
                .underline()
        }
            .buttonStyle(GNOPlainButtonStyle())
            .sheet(isPresented: $showSafariController) {
                SafariViewController(url: self.url)
            }
    }
}
