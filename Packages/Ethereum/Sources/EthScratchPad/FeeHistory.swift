//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

struct FeeHistory {
    var oldestBlock: Block
    var baseFeePerGas: [Sol.UInt256]
    var gasUsedRatio: [Sol.UInt64]
    var reward: [[Sol.UInt256]]
}
