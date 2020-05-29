//
//  TitleText.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TitleText: View {
    var label: String

    init(_ value: String) {
        label = value
    }

    var body: some View {
        Text(label).font(Font.gnoTitle3).foregroundColor(.gnoDarkBlue)
    }
}

struct TitleText_Previews: PreviewProvider {
    static var previews: some View {
        TitleText("Test")
    }
}
