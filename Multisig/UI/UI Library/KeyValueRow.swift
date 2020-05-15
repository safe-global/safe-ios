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

    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading) {
            BoldText(key)
            Text(value)
                .font(Font.gnoBody.weight(.medium))
                .foregroundColor(Color.gnoMediumGrey)
        }
    }
}

struct KeyValueRow_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueRow("Key", "Value")
    }
}
