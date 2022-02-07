//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node.Transaction {
    public static let transactionTypeLegacy: Sol.UInt64 = 0
}
extension Node {
    public class TransactionLegacy: Transaction {
        public override init() {
            super.init()
            fee = FeeLegacy()
            signature = SignatureLegacy()
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            fee = try FeeLegacy(from: decoder)
            signature = try SignatureLegacy(from: decoder)
        }

        public var feeLegacy: FeeLegacy {
            get { fee as! FeeLegacy }
            set { fee = newValue }
        }

        public var signatureLegacy: SignatureLegacy {
            get { signature as! SignatureLegacy }
            set { signature = newValue }
        }
    }

    public class FeeLegacy: Fee {
        public var gasPrice: Sol.UInt256 = 0

        public enum JsonKey: String, CodingKey {
            case gasPrice
        }

        public override init() {
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

    public class SignatureLegacy: Signature {
        public var v: Sol.UInt256 = 0
        public var r: Sol.UInt256 = 0
        public var s: Sol.UInt256 = 0

        public enum JsonKey: String, CodingKey {
            case v
            case r
            case s
        }

        public override init() {
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