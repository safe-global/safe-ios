//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

public enum NodeBlockId {
    case blockNumber(Sol.UInt256)
    case blockHash(Node.Hash, canonical: Bool = false)
    case blockTag(NodeBlockTag)
    /// Legacy parameter, use `blockNumber` instead.
    case number(Sol.UInt256)
}

struct NodeBlockNumber: Codable {
    var blockNumber: NodeQuantity<Sol.UInt256>
}

struct NodeBlockHash: Codable {
    var blockHash: NodeData<Node.Hash>
    var requireCanonical: Bool? = false
}

public enum NodeBlockTag: String, Codable {
    case latest
    case earliest
    case pending
}

extension NodeBlockId: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = (try? container.decode(NodeQuantity<Sol.UInt256>.self)) {
            self = .number(value.value)
        }
        else if let value = (try? container.decode(NodeBlockNumber.self)) {
            self = .blockNumber(value.blockNumber.value)
        }
        else if let value = (try? container.decode(NodeBlockHash.self)) {
            self = .blockHash(value.blockHash.value, canonical: value.requireCanonical ?? false)
        }
        else if let value = (try? container.decode(NodeBlockTag.self)) {
            self = .blockTag(value)
        }
        else {
            throw DecodingError.typeMismatch(
                    type(of: self),
                    DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Unknown block specifier",
                            underlyingError: nil)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .blockNumber(let number):
            let value = NodeBlockNumber(blockNumber: NodeQuantity(number))
            try container.encode(value)
        case .blockHash(let hash, let canonical):
            let value = NodeBlockHash(blockHash: NodeData(hash), requireCanonical: canonical)
            try container.encode(value)
        case .blockTag(let tag):
            try container.encode(tag)
        case .number(let number):
            try container.encode(NodeQuantity(number))
        }
    }
}