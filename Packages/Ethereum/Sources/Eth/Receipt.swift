//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct Receipt: Codable {
        public var transactionHash: Hash
        public var blockPath: BlockPath
        public var status: Sol.UInt8
        public var from: Sol.Address
        public var to: Sol.Address?
        public var contractAddress: Sol.Address?
        public var gasUsed: Sol.UInt64
        public var cumulativeGasUsed: Sol.UInt64
        public var effectiveGasPrice: Sol.UInt256
        public var logs: [Log]
        public var logsBloom: Data

        public var isSuccess: Bool {
            status == Self.STATUS_SUCCESS
        }

        static let STATUS_SUCCESS: Sol.UInt8 = 1
        static let STATUS_FAILED: Sol.UInt8 = 0

        enum JsonKey: String, CodingKey {
            case transactionHash
            case status
            case from
            case to
            case contractAddress
            case cumulativeGasUsed
            case gasUsed
            case effectiveGasPrice
            case logs
            case logsBloom
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JsonKey.self)
            to = try container.decodeIfPresent(NodeData<Sol.Address>.self, forKey: .to)?.value
            from = try container.decode(NodeData<Sol.Address>.self, forKey: .from).value
            contractAddress = try container.decodeIfPresent(NodeData<Sol.Address>.self, forKey: .contractAddress)?.value
            transactionHash = try container.decode(NodeData<Hash>.self, forKey: .transactionHash).value
            gasUsed = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .gasUsed).value
            cumulativeGasUsed = try container.decode(NodeQuantity<Sol.UInt64>.self, forKey: .cumulativeGasUsed).value
            effectiveGasPrice = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .effectiveGasPrice).value
            status = try container.decode(NodeQuantity<Sol.UInt8>.self, forKey: .status).value
            logs = try container.decode([Log].self, forKey: .logs)
            logsBloom = try container.decode(NodeData<Data>.self, forKey: .logsBloom).value
            blockPath = try BlockPath(from: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JsonKey.self)
            if let to = to {
                try container.encode(NodeData(to), forKey: .to)
            }
            try container.encode(NodeData(from), forKey: .from)
            if let contractAddress = contractAddress {
                try container.encode(NodeData(contractAddress), forKey: .contractAddress)
            }
            try container.encode(NodeData(transactionHash), forKey: .transactionHash)
            try container.encode(NodeQuantity(gasUsed), forKey: .gasUsed)
            try container.encode(NodeQuantity(cumulativeGasUsed), forKey: .cumulativeGasUsed)
            try container.encode(NodeQuantity(effectiveGasPrice), forKey: .effectiveGasPrice)
            try container.encode(NodeQuantity(status), forKey: .status)
            try container.encode(logs, forKey: .logs)
            try container.encode(NodeData(logsBloom), forKey: .logsBloom)
            try blockPath.encode(to: encoder)
        }
    }
}
