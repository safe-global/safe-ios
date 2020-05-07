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

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title).font(Font.gnoHeadline).foregroundColor(.gnoDarkBlue)
    }
}

struct BoldText_Previews: PreviewProvider {
    static var previews: some View {
        BoldText("Hey this is a form header")
    }
}
