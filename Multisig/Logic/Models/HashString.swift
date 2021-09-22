//
//  HashString.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 30.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

struct HashString: Hashable, Codable {
    let hash: Data

    enum HashStringError: String, Error {
        case wrongHashLength = "Hash length should be 32 bytes"
    }

    init(_ hash: Data) {
        self.hash = hash
    }

    init(hex: String) throws {
        let data = Data(hex: hex)
        guard data.count == 32 else { throw HashStringError.wrongHashLength }
        self.hash = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(hex: string)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hash.toHexStringWithPrefix())
    }

}

extension HashString: CustomStringConvertible {
    var description: String {
        hash.toHexStringWithPrefix()
    }
}

extension HashString {
    var highlighted: NSAttributedString {
        let style = GNOTextStyle.tertiary
        let attributedString = NSMutableAttributedString(
            string: description,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: 4))
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: description.count - 4, length: 4))
        return attributedString
    }
}
