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
        public override class var feeType: Fee.Type {
            FeeLegacy.self
        }

        public var feeLegacy: FeeLegacy {
            get { fee as! FeeLegacy }
            set { fee = newValue }
        }

        public override class var signatureType: Signature.Type {
            SignatureLegacy.self
        }

        public var signatureLegacy: SignatureLegacy {
            get { signature as! SignatureLegacy }
            set { signature = newValue }
        }
    }
}
