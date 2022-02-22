//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node {
    public class Transaction: Codable {
        public var type: Sol.UInt64 = 0
        public var to: Sol.Address = 0
        public var from: Sol.Address = 0
        public var value: Sol.UInt256 = 0
        public var data: Data = Data()
        public var nonce: Sol.UInt64 = 0
        public var hash: Hash = Hash()
        public var gas: Sol.UInt64 = 0
        public var fee: Fee!
        public var signature: Signature!
        public var blockPath: BlockPath = BlockPath()

        public init() {
            fee = Self.feeType.init()
            signature = Self.signatureType.init()
        }

        public enum JsonKey: String, CodingKey {
            case from
            case gas
            case hash
            case input
            case nonce
            case to
            case type
            case value
        }

        public class var feeType: Fee.Type {
            Fee.self
        }

        public class var signatureType: Signature.Type {
            Signature.self
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            type = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .type).value
            to = try container.decode(NodeData<Sol.Address>.self, forKey: .to).value
            from = try container.decode(NodeData<Sol.Address>.self, forKey: .from).value
            data = try container.decode(NodeData<Data>.self, forKey: .input).value
            nonce = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .nonce).value
            hash = try container.decode(NodeData<Hash>.self, forKey: .hash).value
            gas = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .gas).value
            blockPath = try BlockPath(from: decoder)
            fee = try Self.feeType.init(from: decoder)
            signature = try Self.signatureType.init(from: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(type), forKey: .type)
            try container.encode(NodeData(to), forKey: .to)
            try container.encode(NodeData(from), forKey: .from)
            try container.encode(NodeQuantity(nonce), forKey: .nonce)
            try container.encode(NodeData(hash), forKey: .hash)
            try container.encode(NodeQuantity(gas), forKey: .gas)
            try blockPath.encode(to: encoder)
            try fee.encode(to: encoder)
            try signature.encode(to: encoder)
        }
    }
}
