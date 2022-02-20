//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

extension Node {
    public class eth_getTransactionByHash: NodeGetTransactionMethod {
        public var hash: NodeData<Hash>

        public init(hash: NodeData<Hash>, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.hash = hash
            super.init()
            self.completion = completion
        }

        public convenience init(hash: Hash, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.init(hash: NodeData(hash), completion: completion)
        }

        public required init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            hash = try container.decode(NodeData<Hash>.self)
            try super.init(from: decoder)
        }

        public override func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(hash)
        }
    }
}
