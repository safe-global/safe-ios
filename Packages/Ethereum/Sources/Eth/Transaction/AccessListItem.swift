//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct AccessListItem: Codable {
        public var address: Sol.Address = 0
        public var storageKeys: [Hash] = []

        enum JsonKey: String, CodingKey {
            case address
            case storageKeys
        }

        public init(address: Sol.Address, storageKeys: [Hash]) {
            self.address = address
            self.storageKeys = storageKeys
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            address = try container.decode(NodeData<Sol.Address>.self, forKey: .address).value
            storageKeys = try container.decode([NodeData<Hash>].self, forKey: .storageKeys).map(\.value)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeData(address), forKey: .address)
            try container.encode(storageKeys.map(NodeData.init), forKey: .storageKeys)
        }
    }
}