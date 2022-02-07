//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import JsonRpc2
import Json

extension Node {
    public struct eth_getTransactionByHash: JsonRpc2MethodWithCompletion, Codable {
        public var hash: NodeData<Hash>
        public var completion: (Result<Transaction?, Error>) -> Void = { _ in }

        public init(hash: NodeData<Hash>, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.hash = hash
            self.completion = completion
        }

        public init(hash: Hash, completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.init(hash: NodeData(hash), completion: completion)
        }

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            hash = try container.decode(NodeData<Hash>.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(hash)
        }

        public func convert(json: Json.Element) throws -> Transaction? {
            guard let baseTransaction = try json.convert(to: Transaction?.self) else { return nil }
            switch baseTransaction.type {
            case TransactionLegacy.transactionTypeLegacy:
                let result = try json.convert(to: TransactionLegacy.self)
                return result

            case Transaction2930.transactionType2930:
                let result = try json.convert(to: Transaction2930.self)
                return result

            case Transaction1559.transactionType1559:
                let result = try json.convert(to: Transaction1559.self)
                return result

            default:
                return baseTransaction
            }
        }
    }
}