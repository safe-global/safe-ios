//
//  TitleText.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TitleText: View {
    let label: String
    let color: Color

    init(_ label: String, color: Color = .gnoDarkBlue) {
        self.label = label
        self.color = color
    }

    var body: some View {
        Text(label).font(Font.gnoTitle3).foregroundColor(color)
    }
}

struct TitleText_Previews: PreviewProvider {
    static var previews: some View {
        TitleText("Test")
    }
}
