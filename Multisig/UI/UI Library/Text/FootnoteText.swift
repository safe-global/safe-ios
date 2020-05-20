//
//  FootnoteText.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FootnoteText: View {
    var label: String

    init(_ value: String) {
        label = value
    }

    var body: some View {
        Text(label).font(Font.gnoFootnote.weight(.medium)).foregroundColor(.gnoDarkGrey)
    }
}

struct FootnoteText_Previews: PreviewProvider {
    static var previews: some View {
        FootnoteText("Hello")
    }
}
