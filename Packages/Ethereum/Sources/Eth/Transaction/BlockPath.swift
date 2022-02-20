//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node {
    public struct BlockPath {
        public var blockHash: Hash = Hash()
        public var blockNumber: Sol.UInt256 = 0
        public var transactionIndex: Sol.UInt64 = 0

        public init() {}

        public init(blockHash: Hash, blockNumber: Sol.UInt256, transactionIndex: Sol.UInt64) {
            self.blockHash = blockHash
            self.blockNumber = blockNumber
            self.transactionIndex = transactionIndex
        }
    }
}