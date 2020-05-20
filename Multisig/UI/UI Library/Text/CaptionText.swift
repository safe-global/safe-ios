//
//  CaptionText.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CaptionText: View {
    var label: String

    init(_ value: String) {
        label = value
    }

    var body: some View {
        Text(label).font(Font.gnoCaption1).foregroundColor(.gnoHold)
    }
}

struct CaptionText_Previews: PreviewProvider {
    static var previews: some View {
        CaptionText("Hello")
    }
}
