//
//  LinkButton.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct LinkButton: View {
    private let name: String
    private let url: URL

    init(_ name: String, url: URL) {
        self.name = name
        self.url = url
    }

    @State
    private var showSafariController = false

    var body: some View {
        Button(action: { self.showSafariController = true }) {
            Text(name).underline()
        }
        .buttonStyle(GNOPlainButtonStyle())
        .sheet(isPresented: $showSafariController) {
            SafariViewController(url: self.url)
        }
    }
}
