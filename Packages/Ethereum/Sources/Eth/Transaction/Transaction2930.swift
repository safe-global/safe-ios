//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node.Transaction {
    public static let transactionType2930: Sol.UInt64 = 1
}

extension Node {
    public class Transaction2930: TransactionLegacy {
        public var chainId: Sol.UInt256 = 0
        public var accessList: [AccessListItem] = []

        enum JsonKey: String, CodingKey {
            case chainId
            case accessList
        }

        public override class var signatureType: Signature.Type {
            Signature2930.self
        }

        public var signature2930: Signature2930 {
            get { signature as! Signature2930 }
            set { signature = newValue }
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let container = try decoder.container(keyedBy: JsonKey.self)
            chainId = try container.decode(NodeQuantity<Sol.UInt256>.self, forKey: .chainId).value
            accessList = try container.decode([AccessListItem].self, forKey: .accessList)
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var container = encoder.container(keyedBy: JsonKey.self)
            try container.encode(NodeQuantity(chainId), forKey: .chainId)
            try container.encode(accessList, forKey: .accessList)
        }

    }
}
