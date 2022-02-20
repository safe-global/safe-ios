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
        public override class var feeType: Fee.Type {
            Fee1559.self
        }
        public var fee1559: Fee1559 {
            get { fee as! Fee1559 }
            set { fee = newValue }
        }
    }
}
