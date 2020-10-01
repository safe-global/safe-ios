//
//  AddressString.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AddressString: Hashable, Decodable {
    let address: Address

    var data32: Data {
        return address.data.leftPadded(to: 32)
    }

    init?(_ string: String) {
        guard let value = Address(string) else { return nil }
        address = value
    }

    init(_ address: Address) {
        self.address = address
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        do {
            address = try Address(from: value)
        } catch {
            let message = "Failed to decode address: \(error.localizedDescription): \(value)"
            let context = DecodingError.Context.init(codingPath: container.codingPath, debugDescription: message)
            throw DecodingError.typeMismatch(Address.self, context)
        }
    }
}

extension AddressString: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        if let v = AddressString(value) {
            self = v
        } else {
            assertionFailure("Invalid literal address: \(value)")
            self = .init(.zero)
        }
    }
}

extension AddressString: CustomStringConvertible {
    var description: String {
        address.checksummed
    }
}
