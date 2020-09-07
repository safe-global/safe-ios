//
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// https://github.com/matter-labs/web3swift

public extension Data {
    static func randomBytes(length: Int) -> Data? {
        for _ in 0...1024 {
            var data = Data(repeating: 0, count: length)
            let result = data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) -> Int32? in
                if let bodyAddress = body.baseAddress, body.count > 0 {
                    let pointer = bodyAddress.assumingMemoryBound(to: UInt8.self)
                    return SecRandomCopyBytes(kSecRandomDefault, 32, pointer)
                } else {
                    return nil
                }
            }
            if let notNilResult = result, notNilResult == errSecSuccess {
                return data
            }
        }
        return nil
    }

    func bitsInRange(_ startingBit:Int, _ length:Int) -> UInt64? { //return max of 8 bytes for simplicity, non-public
        if startingBit + length / 8 > self.count, length > 64, startingBit > 0, length >= 1 {return nil}
        let bytes = self[(startingBit/8) ..< (startingBit+length+7)/8]
        let padding = Data(repeating: 0, count: 8 - bytes.count)
        let padded = bytes + padding
        guard padded.count == 8 else {return nil}
        let pointee = padded.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            body.baseAddress?.assumingMemoryBound(to: UInt64.self).pointee
        }
        guard let ptee = pointee else {return nil}
        var uintRepresentation = UInt64(bigEndian: ptee)
        uintRepresentation = uintRepresentation << (startingBit % 8)
        uintRepresentation = uintRepresentation >> UInt64(64 - length)
        return uintRepresentation
    }

    func setLengthLeft(_ toBytes: UInt64, isNegative:Bool = false ) -> Data? {
        let existingLength = UInt64(self.count)
        if (existingLength == toBytes) {
            return self
        } else if (existingLength > toBytes) {
            return nil
        }
        var data:Data
        if (isNegative) {
            data = Data(repeating: UInt8(255), count: Int(toBytes - existingLength))
        } else {
            data = Data(repeating: UInt8(0), count: Int(toBytes - existingLength))
        }
        data.append(self)
        return data
    }
}
