//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

class Block {
    var number: Sol.UInt256
    var hash: Hash
    var parent: Block

    var sha3Uncles: Hash
    var uncles: [Block]

    var stateRoot: Hash
    var state: [Account]

    var transactionsRoot: Hash
    var transactions: [Transaction]
    var logsBloom: BloomFilter

    var gasLimit: Sol.UInt64
    var gasUsed: Sol.UInt64
    var baseFeePerGas: Sol.UInt256

    var size: Sol.UInt64

    var miner: Account
    var nonce: Sol.UInt8
    var extraData: Data

    var difficulty: Sol.UInt256
    var totalDifficulty: Sol.UInt256

    var timestamp: Sol.UInt64
}
