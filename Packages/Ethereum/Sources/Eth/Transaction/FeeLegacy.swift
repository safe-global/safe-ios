//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public class FeeLegacy: Fee {
        public var gasPrice: Sol.UInt256 = 0

        public enum JsonKey: String, CodingKey {
            case gasPrice
        }

        public required init() {
            super.init()
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let container = try decoder.container(keyedBy: JsonKey.self)
            gasPrice = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .gasPrice).value
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(gasPrice), forKey: .gasPrice)
        }
    }
}