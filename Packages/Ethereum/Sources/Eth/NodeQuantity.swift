//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

public struct NodeQuantity<T> where T: FixedWidthInteger {
    public var value: T

    public init() {
        self.init(.init())
    }

    public init(_ value: T) {
        self.value = value
    }
}

extension NodeQuantity: Codable {
    // A Quantity value MUST be hex-encoded.
    // A Quantity value MUST be “0x”-prefixed.
    // A Quantity value MUST be expressed using the fewest possible hex digits per byte.
    // A Quantity value MUST express zero as “0x0”.

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard string.hasPrefix("0x") else {
            throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                            debugDescription: "Quantity value MUST be 0x-prefixed",
                            underlyingError: nil)
            )
        }

        guard let value = T(string.dropFirst(2), radix: 16) else {
            throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                            debugDescription: "Quantity value MUST be hex-encoded",
                            underlyingError: nil)
            )
        }

        self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    public var hex: String {
        let result: String
        if value == 0 {
            result = "0x0"
        } else {
            let hex = String(value, radix: 16)
            let minHexDigits = String(hex.drop { $0 == "0" })
            result = "0x" + minHexDigits
        }
        return result
    }
}