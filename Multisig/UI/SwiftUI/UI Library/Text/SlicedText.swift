//
//  SlicedText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SlicedText: View {
    var string: SlicedString
    var style: Style = .default
    var font: Font = .body

    var truncated: SlicedString {
        string.truncated(in: style.truncate)
    }

    var body: some View {
        (
            Text(truncated.start).foregroundColor(style.startColor) +
            Text(truncated.middle).foregroundColor(style.middleColor) +
            Text(truncated.end).foregroundColor(style.endColor)
        )
        .font(font)
        .tracking(-0.41)
    }

    struct Style {
        let startColor: Color
        let middleColor: Color
        let endColor: Color
        let truncate: Truncation

        typealias Truncation = SlicedString.Truncation
    }

    func style(_ style: Style, font: Font = .body) -> Self {
        .init(string: string, style: style, font: font)
    }

}


extension SlicedText.Style {

    static let `default` = Self.init(color: .labelPrimary, truncate: .none)

    init(color: Color, truncate: Truncation) {
        self.init(startColor: color, middleColor: color, endColor: color, truncate: truncate)
    }

    init(middleColor: Color, sideColor: Color, truncate: Truncation) {
        self.init(startColor: sideColor, middleColor: middleColor, endColor: sideColor, truncate: truncate)
    }

}

extension SlicedText {
    init(_ text: String) {
        self.init(string: SlicedString(text: text))
    }
}

struct SlicedText_Previews: PreviewProvider {
    static var previews: some View {
        SlicedText("Hello, world!")
    }
}
