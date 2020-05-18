//
//  ValueText.swift
//  Multisig
//
//  Created by Moaaz on 5/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ValueText: View {
    var label: String

    init(_ value: String) {
        label = value
    }

    var body: some View {
        Text(label).font(Font.gnoBody.weight(.medium)).foregroundColor(.gnoDarkGrey)
    }
}

struct ValueText_Previews: PreviewProvider {
    static var previews: some View {
        ValueText("Text")
    }
}
