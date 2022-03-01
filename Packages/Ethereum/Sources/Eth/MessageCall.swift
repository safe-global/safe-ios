//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct MessageCall: Codable {
        public var from: Sol.Address?
        public var to: Sol.Address?
        public var value: Sol.UInt256?
        public var data: Data?
        
        public init(from: Sol.Address? = nil, to: Sol.Address? = nil, value: Sol.UInt256? = nil, data: Data? = nil) {
            self.from = from
            self.to = to
            self.value = value
            self.data = data
        }
        
        enum JsonKey: String, CodingKey {
            case from, to, value, data
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            from = try container.decodeIfPresent(NodeData<Sol.Address>.self, forKey: .from)?.value
            to = try container.decodeIfPresent(NodeData<Sol.Address>.self, forKey: .to)?.value
            value = try container.decodeIfPresent(NodeQuantity<Sol.UInt256>.self, forKey: .value)?.value
            data = try container.decodeIfPresent(NodeData<Data>.self, forKey: .data)?.value
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            if let from = from {
                try container.encode(NodeData(from), forKey: .from)
            }
            if let to = to {
                try container.encode(NodeData(to), forKey: .to)
            }
            if let value = value {
                try container.encode(NodeQuantity(value), forKey: .value)
            }
            if let data = data {
                try container.encode(NodeData(data), forKey: .data)
            }
        }

        public init(_ tx: Transaction) {
            if tx.from != 0 {
                from = tx.from
            }
            if tx.to != 0 {
                to = tx.to
            }
            if tx.value != 0 {
                value = tx.value
            }
            if !tx.data.isEmpty {
                data = tx.data
            }
        }
    }
}