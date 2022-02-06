//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

let TransactionType2930: Sol.UInt64 = 1

class Transaction2930: Transaction {
    var accessList: [AccessListItem]
}

class Signature2930: Signature {
    var yParity: Sol.UInt256
    var r: Sol.UInt256
    var s: Sol.UInt256
}

struct AccessListItem {
    var address: Sol.Address
    var storageKeys: [Hash]
}
