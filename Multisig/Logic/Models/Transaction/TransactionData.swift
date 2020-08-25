//
//  TransactionData.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionData: Decodable, Hashable {
    let method: String
    let parameters: [TransactionDataParameter]
}

struct TransactionDataParameter: Hashable {
    let name: String
    let type: String
    let value: String?
    let decodedData: DataDecodedParameterValue?

    static func == (lhs: TransactionDataParameter, rhs: TransactionDataParameter) -> Bool {
        (lhs.name, lhs.type, lhs.value)  == (rhs.name, rhs.type, rhs.value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(value)
    }
}

extension TransactionDataParameter: Decodable {

    enum CodingKeys: CodingKey {
        case name, type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        // only String values are currently supported in the app
        value = try? container.decode(String.self, forKey: .value)
        decodedData = try container.decode(DataDecodedParameterValueWrapper.self, forKey: .value).value
    }

    var addressValue: Address? {
        guard let value = value else { return nil }
        return Address(value)
    }

    var uint256Value: UInt256? {
        guard let value = value else { return nil }
        return UInt256(value)
    }

    var bytesValue: Data? {
        guard let value = value else { return nil }
        return Data(exactlyHex: value)
    }
}
