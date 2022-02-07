//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node.Transaction {
    public static let transactionType1559: Sol.UInt64 = 2
}

extension Node {
    public class Transaction1559: Transaction2930 {
        public override init() {
            super.init()
            fee = Fee1559()
        }

        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class Fee1559: Fee {
        public var maxFeePerGas: Sol.UInt256 = 0
        public var maxPriorityFeePerGas: Sol.UInt256 = 0
        public var maxBaseFee: Sol.UInt256 {
            maxFeePerGas - maxPriorityFeePerGas
        }
    }
}
