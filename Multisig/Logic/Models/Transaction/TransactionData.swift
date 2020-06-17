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

struct TransactionDataParameter: Decodable, Hashable {
    let name: String
    let type: String
    let value: String?

    enum CodingKeys: CodingKey {
        case name, type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        // only String values are currently supported in the app
        value = try? container.decode(String.self, forKey: .value)
    }

    var addressValue: Address? {
        guard let value = value else { return nil }
        return Address(value)
    }

    var uint256Value: UInt256? {
        guard let value = value else { return nil }
        return UInt256(value)
    }

}
