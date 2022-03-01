//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct BlockPath: Codable, Equatable {
        public var blockHash: Hash = Hash()
        public var blockNumber: Sol.UInt256 = 0
        public var transactionIndex: Sol.UInt64 = 0

        public init() {}

        public init(blockHash: Hash, blockNumber: Sol.UInt256, transactionIndex: Sol.UInt64) {
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.transactionIndex = transactionIndex
        }

        enum JsonKey: String, CodingKey {
            case blockHash
            case blockNumber
            case transactionIndex
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            blockNumber = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .blockNumber).value
            blockHash = try container.decode(NodeData<Hash>.self, forKey: .blockHash).value
            transactionIndex = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .transactionIndex).value
        }

        public init?(ifPresent decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            let blockNumber = try container.decodeIfPresent(NodeQuantity<Sol.UInt256>.self, forKey: .blockNumber)?.value
            let blockHash = try container.decodeIfPresent(NodeData<Hash>.self, forKey: .blockHash)?.value
            let transactionIndex = try container.decodeIfPresent(NodeQuantity<Sol.UInt64>.self, forKey: .transactionIndex)?.value
            guard let blockNumber = blockNumber, let blockHash = blockHash, let transactionIndex = transactionIndex else {
                return nil
            }
            self.blockNumber = blockNumber
            self.blockHash = blockHash
            self.transactionIndex = transactionIndex
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(blockNumber), forKey: .blockNumber)
            try container.encode(NodeData(blockHash), forKey: .blockHash)
            try container.encode(NodeQuantity(transactionIndex), forKey: .transactionIndex)
        }
    }
}
