//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import JsonRpc2

extension Node {
    public struct eth_getTransactionReceipt: JsonRpc2MethodWithCompletion, Codable {
        public var hash: NodeData<Hash>
        public var completion: (Result<Receipt?, Error>) -> Void = { _ in }

        public init(hash: NodeData<Hash>, completion: @escaping (Result<Receipt?, Error>) -> ()) {
            self.hash = hash
            self.completion = completion
        }

        public init(hash: Hash, completion: @escaping (Result<Receipt?, Error>) -> ()) {
            self.hash = NodeData(hash)
            self.completion = completion
        }

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            hash = try container.decode(NodeData<Hash>.self)

        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(hash)
        }
    }
}
