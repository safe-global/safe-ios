//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct Log: Codable, Equatable {
        public var address: Sol.Address
        public var data: Data
        public var topics: [Sol.Bytes32]
        public var removed: Bool
        public var logIndex: Sol.UInt64?
        public var blockPath: BlockPath?
        public var transactionHash: Hash?

        public init(address: Sol.Address, data: Data, topics: [Sol.Bytes32], removed: Bool, logIndex: Sol.UInt64?, blockPath: BlockPath?, transactionHash: Hash?) {
            self.address = address
            self.data = data
            self.topics = topics
            self.removed = removed
            self.logIndex = logIndex
            self.blockPath = blockPath
            self.transactionHash = transactionHash
        }

        public enum JsonKey: String, CodingKey {
            case address
            case data
            case topics
            case removed
            case logIndex
            case transactionHash
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            address = try container.decode(NodeData<Sol.Address>.self, forKey: .address).value
            data = try container.decode(NodeData<Data>.self, forKey: .data).value
            topics = try container.decode([NodeData<Sol.Bytes32>].self, forKey: .topics).map(\.value)
            removed = try container.decode(Bool.self, forKey: .removed)
            logIndex = try container.decodeIfPresent(NodeQuantity<Sol.UInt64>.self, forKey: .logIndex)?.value
            transactionHash = try container.decodeIfPresent(NodeData<Hash>.self, forKey: .transactionHash)?.value
            blockPath = try BlockPath(ifPresent: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeData(address), forKey: .address)
            try container.encode(NodeData(data), forKey: .data)
            try container.encode(topics.map(NodeData.init), forKey: .topics)
            try container.encode(removed, forKey: .removed)
            if let logIndex = logIndex {
                try container.encode(NodeQuantity(logIndex), forKey: .logIndex)
            }
            if let transactionHash = transactionHash {
                try container.encode(NodeData(transactionHash), forKey: .transactionHash)
            }
            if let blockPath = blockPath {
                try blockPath.encode(to: encoder)
            }
        }
    }
}
