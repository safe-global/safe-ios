//
//  eth_getTransactionByBlockHashAndIndex.swift
//  
//
//  Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public class eth_getTransactionByBlockHashAndIndex: NodeGetTransactionMethod {
        public var blockHash: NodeData<Hash>
        public var transactionIndex: NodeQuantity<Sol.UInt64>

        public init(blockHash: NodeData<Hash>, transactionIndex: NodeQuantity<Sol.UInt64>, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.blockHash = blockHash
            self.transactionIndex = transactionIndex
            super.init(completion: completion)
        }

        public init(blockHash: Hash, transactionIndex: Sol.UInt64, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.blockHash = NodeData(blockHash)
            self.transactionIndex = NodeQuantity(transactionIndex)
            super.init(completion: completion)
        }

        public required init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            blockHash = try container.decode(NodeData<Hash>.self)
            transactionIndex = try container.decode(NodeQuantity<Sol.UInt64>.self)
            try super.init(from: decoder)
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.unkeyedContainer()
            try container.encode(blockHash)
            try container.encode(transactionIndex)
        }
    }
}
