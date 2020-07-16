//
//  CopyButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CopyButton<Content: View>: View {

    var value: String?
    var content: Content

    init(_ value: String? = nil, @ViewBuilder _ content: () -> Content) {
        self.value = value
        self.content = content()
    }

    var body: some View {
        Button(action: {
            Pasteboard.string = self.value
        }) {
            content
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

extension CopyButton {
    init(_ address: Address, @ViewBuilder _ content: () -> Content) {
        self.init(address.checksummed, content)
    }
}

struct CopyButton_Previews: PreviewProvider {
    static var previews: some View {
        CopyButton("Paste") {
            Text("Copy")
        }
    }
}
