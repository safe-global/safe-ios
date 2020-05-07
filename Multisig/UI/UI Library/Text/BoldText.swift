//
//  BoldText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BoldText: View {

    var title: String
    var font: Font

    init(_ title: String, font: Font = .gnoHeadline) {
        self.title = title
        self.font = font
    }

    var body: some View {
        Text(title).font(font).foregroundColor(.gnoDarkBlue)
    }
}

struct BoldText_Previews: PreviewProvider {
    static var previews: some View {
        BoldText("Hey this is a form header")
    }
}
