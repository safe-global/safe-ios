//
//  SlicedString.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SlicedString {
    let value: String
    let start: String
    let middle: String
    let end: String
}

extension SlicedString {
    init(text: String, prefix prefixCount: Int = 4, suffix suffixCount: Int = 4) {
        value = text
        start = String(text.prefix(prefixCount))
        middle = String(text.dropFirst(prefixCount).dropLast(suffixCount))
        end = String(text.dropFirst(prefixCount).suffix(suffixCount))
    }
}

extension SlicedString {
    enum Truncation {
        case none, start, middle, end
    }

    func truncated(in position: Truncation) -> Self {
        let ellipsis = "…"
        return .init(value: value,
              start: position == .start ? ellipsis : start,
              middle: position == .middle ? ellipsis : middle,
              end: position == .end ? ellipsis : end)
    }
}

