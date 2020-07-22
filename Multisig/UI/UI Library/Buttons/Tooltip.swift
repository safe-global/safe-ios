//
//  Tooltip.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct Tooltip: View {
    let text: String
    var body: some View {
        Text(self.text)
            .font(.gnoCallout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gnoSnowwhite)
            .cornerRadius(8)
            .gnoShadow()
    }
}

extension Tooltip {
    init(_ text: String) {
        self.text = text
    }
}

struct Tooltip_Previews: PreviewProvider {
    static var previews: some View {
        Tooltip("Hello")
    }
}
