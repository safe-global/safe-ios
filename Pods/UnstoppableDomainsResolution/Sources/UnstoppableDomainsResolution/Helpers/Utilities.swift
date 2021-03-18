//
//  Utilities.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class Utillities {
    static func isNotEmpty(_ value: String?) -> Bool {
        guard let value = value else { return false }
        return Self.isNotEmpty(value)
    }

    static func isNotEmpty(_ value: String) -> Bool {
        let nullValues = [
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000"
        ]
        return !(value.isEmpty || nullValues.contains(value))
    }

    static func isNotEmpty(_ array: [Any]) -> Bool {
        return array.count > 0
    }
}

extension String {
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }

    func addHexPrefix() -> String {
        if !self.hasPrefix("0x") {
            return "0x" + self
        }
        return self
    }
}
