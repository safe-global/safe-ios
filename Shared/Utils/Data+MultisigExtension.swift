//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoSwift

// MARK: - Hex String to Data conversion
public extension Data {

    /// Creates data from hex string, padding to even byte character count from the left with 0.
    /// For example, "0x1" will become "0x01".
    ///
    /// - Parameter ethHex: hex string.
    init(ethHex: String) {
        var value = ethHex
        while value.hasPrefix("0x") || value.hasPrefix("0X") { value = String(value.dropFirst(2)) }
        // if ethHex is not full byte, Data(hex:) adds nibble at the end, but we need it in the beginning
        let paddingToByte = value.count % 2 == 1 ? "0" : ""
        value = paddingToByte + value
        self.init(hex: value)
    }

    init?(exactlyHex hex: String) {
        var value = hex.lowercased()
        if value.hasPrefix("0x") {
            value.removeFirst(2)
        }
        guard value.rangeOfCharacter(from: CharacterSet.hexadecimals.inverted) == nil else {
            return nil
        }
        self.init(hex: hex)
    }

    func toHexStringWithPrefix() -> String {
        "0x" + toHexString()
    }

    /// Pads data with `value` from the left to total width of `count`
    ///
    /// - Parameters:
    ///   - count: total padded with=
    ///   - value: padding value, default is 0
    /// - Returns: padded data of size `count`
    func leftPadded(to count: Int, with value: UInt8 = 0) -> Data {
        if self.count >= count { return self }
        return Data(repeating: value, count: count - self.count) + self
    }

    func rightPadded(to count: Int, with value: UInt8 = 0) -> Data {
        if self.count >= count { return self }
        return self + Data(repeating: value, count: count - self.count)
    }

    func endTruncated(to count: Int) -> Data {
        guard self.count > count else { return self }
        return prefix(count)
    }

    init?(randomOfSize count: Int) {
        var bytes: [UInt8] = .init(repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            return nil
        }
        self.init(bytes)
    }
}
