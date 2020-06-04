//
//  BodyText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BodyText: View {

    var label: String

    var color: Color
    init(_ value: String, textColor: Color = .gnoDarkBlue) {
        label = value
        color = textColor
    }

    var body: some View {
        Text(label).font(Font.gnoBody.weight(.medium)).foregroundColor(color)
    }
}

struct BodyText_Previews: PreviewProvider {
    static var previews: some View {
        BodyText("Hello")
    }
}
