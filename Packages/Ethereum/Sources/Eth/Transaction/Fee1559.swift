//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public class Fee1559: Fee {
        public var maxFeePerGas: Sol.UInt256 = 0
        public var maxPriorityFeePerGas: Sol.UInt256 = 0
        public var baseFee: Sol.UInt256 {
            maxFeePerGas - maxPriorityFeePerGas
        }

        public enum JsonKey: String, CodingKey {
            case maxFeePerGas
            case maxPriorityFeePerGas
        }

        public required init() {
            super.init()
        }

        public init(maxFeePerGas: Sol.UInt256, maxPriorityFeePerGas: Sol.UInt256) {
            self.maxFeePerGas = maxFeePerGas
            self.maxPriorityFeePerGas = maxPriorityFeePerGas
            super.init()
        }

        public init(maxPriorityFeePerGas: Sol.UInt256, baseFee: Sol.UInt256) {
            self.maxPriorityFeePerGas = maxPriorityFeePerGas
            self.maxFeePerGas = maxPriorityFeePerGas + baseFee
            super.init()
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let container = try decoder.container(keyedBy: JsonKey.self)
            maxFeePerGas = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .maxFeePerGas).value
            maxPriorityFeePerGas = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .maxPriorityFeePerGas).value
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(maxFeePerGas), forKey: .maxFeePerGas)
            try container.encode(NodeQuantity(maxPriorityFeePerGas), forKey: .maxPriorityFeePerGas)
        }
    }
}