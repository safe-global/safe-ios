//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public class eth_getTransactionByBlockNumberAndIndex: NodeGetTransactionMethod {
        public var block: NodeBlockId
        public var transactionIndex: NodeQuantity<Sol.UInt64>

        public init(block: NodeBlockId, transactionIndex: NodeQuantity<Sol.UInt64>, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.block = block
            self.transactionIndex = transactionIndex
            super.init(completion: completion)
        }

        public init(block: NodeBlockId, transactionIndex: Sol.UInt64, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.block = block
            self.transactionIndex = NodeQuantity(transactionIndex)
            super.init(completion: completion)
        }

        public required init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            block = try container.decode(NodeBlockId.self)
            transactionIndex = try container.decode(NodeQuantity<Sol.UInt64>.self)
            try super.init(from: decoder)
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.unkeyedContainer()
            try container.encode(block)
            try container.encode(transactionIndex)
        }
    }
}
