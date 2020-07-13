//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

// see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
class ERC20Metadata: Contract {

    func name() throws -> String? {
        try decodeString(invoke("name()"))
    }

    func symbol() throws -> String? {
        try decodeString(invoke("symbol()"))
    }

    func decimals() throws -> UInt256 {
        try decodeUInt(invoke("decimals()"))
    }

}
