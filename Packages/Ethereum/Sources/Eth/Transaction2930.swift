//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node.Transaction {
    public static let transactionType2930: Sol.UInt64 = 1
}

extension Node {
    public class Transaction2930: Transaction {
        public var chainId: Sol.UInt256 = 0
        public var accessList: [AccessListItem] = []

        public override init() {
            super.init()
            fee = FeeLegacy()
            signature = Signature2930()
        }

        // coding key

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            // decode chain id
            // decode access list
            fee = try FeeLegacy(from: decoder)
            signature = try Signature2930(from: decoder)
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            // encode chain id
            // encode access list
        }
    }

    public class Signature2930: Signature {
        public var yParity: Sol.UInt256 = 0
        public var r: Sol.UInt256 = 0
        public var s: Sol.UInt256 = 0

        // coding key

        // decode y
        // decode r
        // decode s

        // encode y
        // encode r
        // encode s
    }

    public struct AccessListItem {
        public var address: Sol.Address = 0
        public var storageKeys: [Hash] = []
    }
}