//
//  KeyValueRow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct KeyValueRow: View {

    var key: String
    var value: String
    var enableCopy: Bool
    var color: Color
    init(_ key: String, _ value: String, _ enableCopy: Bool = true, _ color: Color = Color.gnoMediumGrey) {
        self.key = key
        self.value = value
        self.enableCopy = enableCopy
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BoldText(key)
            CopyButton(value) {
                Text(value)
                    .font(Font.gnoBody.weight(.medium))
                    .foregroundColor(color)
            }.disabled(!enableCopy)
        }
    }
}

struct KeyValueRow_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRow("Key", "Value")
    }
}
