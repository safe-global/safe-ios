//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension Node {
    public class SignatureLegacy: Signature {
        public var v: Sol.UInt256 = 0
        public var r: Sol.UInt256 = 0
        public var s: Sol.UInt256 = 0

        public enum JsonKey: String, CodingKey {
            case v
            case r
            case s
        }

        public required init() {
            super.init()
        }

        public init(v: Sol.UInt256, r: Sol.UInt256, s: Sol.UInt256) {
            self.v = v
            self.r = r
            self.s = s
            super.init()
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let container = try decoder.container(keyedBy: JsonKey.self)
            v = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .v).value
            r = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .r).value
            s = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .s).value
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(v), forKey: .v)
            try container.encode(NodeQuantity(r), forKey: .r)
            try container.encode(NodeQuantity(s), forKey: .s)
        }
    }
}