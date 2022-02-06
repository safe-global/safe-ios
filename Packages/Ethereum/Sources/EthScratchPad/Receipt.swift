//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

class Receipt {
    var isSuccess: Bool
    var transactionHash: Hash
    var blockPath: BlockPath
    var from: Account
    var to: Account
    var contract: Account
    var gasUsed: Sol.UInt64
    var cumulativeGasUsed: Sol.UInt64
    var effectiveGasPrice: Sol.UInt256
    var logs: [Log]
}