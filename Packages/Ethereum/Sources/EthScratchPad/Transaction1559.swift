//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

let TransactionType1559: Sol.UInt64 = 2

class Transaction1559: Transaction2930 {

}

class Fee1559: Fee {
    var maxFeePerGas: Sol.UInt256
    var maxPriorityFeePerGas: Sol.UInt256
    var baseFee: Sol.UInt256
}
