//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

class Transaction {
    var type: Sol.UInt64
    var to: Account
    var from: Account
    var value: Sol.UInt256
    var data: Data
    var nonce: Sol.UInt64
    var chainId: Sol.UInt256
    var hash: Hash
    var gas: Sol.UInt64
    var fee: Fee
    var signature: Signature
    var blockPath: BlockPath
}

class Fee {}

class Signature {}
