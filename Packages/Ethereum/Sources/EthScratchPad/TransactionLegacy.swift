//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

let TransactionTypeLegacy: Sol.UInt64 = 0

class TransactionLegacy: Transaction {

}

class FeeLegacy: Fee {
    var gasPrice: Sol.UInt256
}

class SignatureLegacy: Signature {
    var v: Sol.UInt256
    var r: Sol.UInt256
    var s: Sol.UInt256
}

