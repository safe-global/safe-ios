//
//  ADPUHandler .swift
//  Test
//
//  Created by Moaaz on 6/14/21.
//

import Foundation

class APDUHandler {
    static let shared = APDUHandler()

    private init() { }

    private let tagID: UInt8 = 0x05

    func sendADPU(message: Data) -> Data {
        var data = Data()
        data.append(tagID)
        data.append(UInt8(0x00))
        data.append(UInt8(0x00))

        let array = withUnsafeBytes(of: Int16(message.count).bigEndian, Array.init)
        array.forEach{ x in data.append(x) }

        data.append(message)

        return data
    }

    func parseADPU(message: Data) throws -> Data? {
        guard message.count > 6, Int8(message[0]) == tagID else {
            throw GSError.LedgerAPDUResponseError()
        }

        guard message[1] == 0 && message[2] == 0 else { return nil }

        let dataLength = try UInt16(message[3]) << 8 | UInt16(message[4])
        let data: Data = message[5..<message.count]
        guard data.count == dataLength else { return nil }
        
        return data
    }
}
