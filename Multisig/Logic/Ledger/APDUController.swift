//
//  APDUHandler.swift
//  Multisig
//
//  Created by Moaaz on 14.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Application Protocol Data Unit
/// https://blog.ledger.com/btchip-doc/bitcoin-technical.html#_lifecycle_management_apdus
/// https://gist.github.com/Wollac/49f0c4e318e42f463b8306298dfb4f4a
class APDUController {
    static private let tagID: UInt8 = 0x05

    static func prepareAPDU(message: Data) -> Data {
        var data = Data()
        data.append(tagID)
        data.append(UInt8(0x00))
        data.append(UInt8(0x00))

        let array = withUnsafeBytes(of: Int16(message.count).bigEndian, Array.init)
        array.forEach { x in data.append(x) }

        data.append(message)

        return data
    }

    /// We assume to get only one message, so no need to batch several messages
    static func parseAPDU(message: Data) -> Data? {
        guard message.count > 6, Int8(message[0]) == tagID else { return nil }
        guard message[1] == 0 && message[2] == 0 else { return nil }
        guard let dataLength = (try? UInt16(message[3]) << 8 | UInt16(message[4])) else { return nil }
        let data = [UInt8](message[5..<message.count])
        guard data.count == dataLength else { return nil }
        return Data(data)
    }

}
