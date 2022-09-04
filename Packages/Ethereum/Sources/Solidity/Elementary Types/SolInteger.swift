//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

public protocol SolInteger: SolAbiEncodable {}

extension SolInteger where Self: FixedWidthInteger {
    public func encode() -> Data {
        // uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
        // int<M>: enc(X) is the big-endian two’s complement encoding of X, padded on the higher-order (left) side with 0xff bytes for negative X and with zero-bytes for non-negative X such that the length is 32 bytes.
        let bytes = bigEndianData()

        let result: Data
        let remainderFrom32 = bytes.count % 32

        if remainderFrom32 == 0 {
            result = bytes
        } else {
            let padding: UInt8 = self < 0 ? 0xff : 0x00
            result = Data(repeating: padding, count: 32 - remainderFrom32) + bytes
        }
        assert(result.count == 32)
        return result
    }

    private func bigEndianData() -> Data {
        let value = bigEndian
        let bytes = stride(from: 0, to: Self.bitWidth, by: 8).map { bitOffset -> UInt8 in
            let shifted = value >> bitOffset
            let byte = (shifted & 0xff).words.first!
            let uint8 = UInt8(byte)
            return uint8
        }
        return Data(bytes)
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        // there must be 32 bytes
        guard offset < data.count - 32 + 1 else {
            throw SolAbiDecodingError.outOfBounds
        }
        // uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
        // int<M>: enc(X) is the big-endian two’s complement encoding of X, padded on the higher-order (left) side with 0xff bytes for negative X and with zero-bytes for non-negative X such that the length is 32 bytes.
        let byteCount = Self.bitWidth / 8
        let remainder32 = byteCount % 32
        let paddingLength = remainder32 == 0 ? 0 : (32 - remainder32)

        let significantBytes = data[offset + paddingLength..<offset + 32]
        self = 0
        for byte in significantBytes {
            self = (self << 8) | Self(byte)
        }

        offset += 32
    }

    public func encodePacked() -> Data {
        // uint<M>: enc(X) is the big-endian encoding of X
        // int<M>: enc(X) is the big-endian two’s complement encoding of X
        return bigEndianData()
    }

    public var canonicalName: String {
        let result = (Self.isSigned ? "int" : "uint") + "\(Self.bitWidth)"
        return result
    }
}
