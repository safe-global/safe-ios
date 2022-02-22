//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import JsonRpc2
import Json

extension Node {
    public class NodeGetTransactionMethod: JsonRpc2MethodWithCompletion, Codable {
        public var completion: (Result<Transaction?, Error>) -> Void = { _ in }

        public init() {
            // empty
        }

        public init(completion: @escaping (Result<Transaction?, Error>) -> ()) {
            self.completion = completion
        }

        public required init(from decoder: Decoder) throws {
            // empty
        }

        public func encode(to encoder: Encoder) throws {
            // empty
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
