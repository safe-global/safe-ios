//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

class Log {
    var from: Account
    var data: Data
    var topics: [Sol.Bytes32]
    var logIndex: Sol.UInt64
    var transactionHash: Hash
    var blockPath: BlockPath

    var block: Block // it's transaction.block
    var transaction: Transaction
}
