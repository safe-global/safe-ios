//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 05.01.22.
//

import Foundation
import Solidity

public protocol RlpCodable {
    init()
    func encode(using coder: RlpCoder) -> Data
    func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable
}

public protocol RlpInteger: RlpCodable, UnsignedInteger, FixedWidthInteger {}

extension Data: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        coder.encode(data: self)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        guard let data = value as? Data else {
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }
        return data
    }
}

extension String: RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        let data = self.data(using: .utf8) ?? Data()
        return coder.encode(data: data)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        guard let data = value as? Data else {
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }
        let result = String(data: data, encoding: .utf8) ?? ""
        return result
    }
}

extension UInt8: RlpInteger {}
extension UInt16: RlpInteger {}
extension UInt32: RlpInteger {}
extension UInt64: RlpInteger {}
extension UInt: RlpInteger {}

extension RlpInteger {
    public func encode(using coder: RlpCoder) -> Data {
        let binary = coder.encode(integer: self)
        let result = coder.encode(binary)
        return result
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        guard let data = value as? Data else {
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }
        let result: Self = try coder.decode(integer: data)
        return result
    }
}

extension Array: RlpCodable where Element == RlpCodable {
    public func encode(using coder: RlpCoder) -> Data {
        coder.encode(array: self)
    }

    public func decode(value: RlpCodable, coder: RlpCoder) throws -> RlpCodable {
        guard let decodedArray = value as? [RlpCodable] else {
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }

        if decodedArray.isEmpty {
            return [Element]()
        }

        let prototypeArray: [RlpCodable]
        if count == decodedArray.count {
            prototypeArray = self
        } else if count == 1 {
            prototypeArray = [Element](repeating: self[0], count: decodedArray.count)
        } else {
            // not matching expectations
            throw RlpCoder.RlpDecodingError.notRlpEncoded
        }

        let items = try zip(decodedArray, prototypeArray).map { decodedValue, itemPrototype in
            try itemPrototype.decode(value: decodedValue, coder: coder)
        }

        return items
    }
}

// port of https://eth.wiki/en/fundamentals/rlp
public struct RlpCoder {

    // MARK: - Public API

    public init() {}

    public func encode(_ value: RlpCodable) -> Data {
        return value.encode(using: self)
    }

    public func decode(prototype: RlpCodable, input: Data) throws -> RlpCodable {
        let decodedCodable = try decode(codable: input)
        let value = try prototype.decode(value: decodedCodable, coder: self)
        return value
    }

    public func decode(codable input: Data) throws -> RlpCodable {
        var offset: Int = 0
        let result = try decode(input, offset: &offset)
        return result
    }

    // MARK: - Encoding

    internal func encode(data input: Data) -> Data {
        if input.count == 1 && input[0] < 0x80 {
            return input
        } else {
            let output = encode(length: UInt64(input.count), offset: 0x80) + input
            return output
        }
    }

    internal func encode(array input: [RlpCodable]) -> Data {
        // concatenate rlp encodings of each item
        let output = input.map(encode(_:)).joined()
        let result = encode(length: UInt64(output.count), offset: 0xc0) + output
        return result
    }

    internal func encode(length: UInt64, offset: UInt8) -> Data {
        if length < 56 {
            let result = UInt8(length) + offset
            return Data([UInt8(result)])
        } else {
            // length is UInt64, so it is guaranteed not to exceed 2^64 (max = 2^64 - 1)
            let encodedLength = encode(integer: length)
            let firstByte = UInt8(encodedLength.count) + offset + 55
            let result = Data([firstByte]) + encodedLength
            return result
        }
    }

    // input: unsigned integer
    // output: big-endian byte array of minimal length without leading zero bytes.
    internal func encode<T>(integer: T) -> Data where T: UnsignedInteger & FixedWidthInteger {
        // If RLP is used to encode a scalar, defined only as a non-negative integer (in N, or in Nx for any x),
        // it must be encoded as the shortest byte array whose big-endian interpretation is the scalar.
        // Thus the RLP of some non-negative integer i is defined as:
        //    (187) RLP(i : i ∈ N) ≡ RLP(BE(i))
        if integer == 0 {
            return Data()
        } else {
            let bigEndian = integer.bigEndian
            let bytes = stride(from: 0, to: T.bitWidth, by: 8)
                .map { bitOffset in
                    UInt8((bigEndian >> bitOffset) & 0xff)
                }
                .drop { byte in
                    byte == 0
                }
            return Data(bytes)
        }
    }

    // MARK: - Decoding

    internal func decode<T>(integer data: Data) throws -> T where T: UnsignedInteger & FixedWidthInteger {
        if data.isEmpty {
            // actually, it is a valid encoding, because the empty data is 0
            throw RlpDecodingError.inputIsNull
        }
        if data.count == 1 {
            return T(data[0])
        }

        // check if fits in 64 bits
        if data.count > T.bitWidth / 8 {
            var error = RlpDecodingError.integerTooBig
            error.message += ": " + data.map { String($0, radix: 16) }.joined()
            throw error
        }

        // When interpreting RLP data, if an expected fragment is decoded as a scalar and leading zeroes are found
        // in the byte sequence, clients are required to consider it non-canonical and treat it in the same manner as
        // otherwise invalid RLP data, dismissing it completely.
        guard data.prefix(while: { $0 == 0 }).isEmpty else {
            throw RlpDecodingError.notRlpEncoded
        }

        // value is in big endian order
        var result = 0 as T
        for byte in data {
            result = (result << 8) | T(byte)
        }
        let output = T(bigEndian: result)
        return output

    }

    internal func decode(array input: Data) throws -> [RlpCodable] {
        let binary = try decode(codable: input)
        guard let result = binary as? [RlpCodable] else {
            throw RlpDecodingError.notRlpEncoded
        }
        return result
    }

    internal func decode(_ input: Data, offset: inout Int) throws -> RlpCodable {
        if input.isEmpty {
            offset = 0
            return input
        }

        //        According to the first byte(i.e. prefix) of input data, and decoding the data type, the length of the actual data and offset;
        // get first byte - prefix
        let prefix = input[0]

        // decode the data type from prefix
        switch (prefix) {
        case 0x00...0x7f:
            //  if the range of the first byte(i.e. prefix) is [0x00, 0x7f] then the data is a string
            // the payload(string) is the first byte itself exactly
            let output = input.subdata(in: 0..<1)
            offset = 1
            return output

        case 0x80...0xb7:
            // if the range of the first byte is [0x80, 0xb7] then the data is a string
            // the the string follows the first byte with length is equal to the first byte minus 0x80
            let output = try shortData(prefix: prefix, typeIdentifier: 0x80, input: input, offset: &offset)
            return output

        case 0xb8...0xbf:
            // if the range of the first byte is [0xb8, 0xbf] then the data is a string
            // the length of the encoded string length is equal to the first byte minus 0xb7
            // the length of the string is encoded binary integer that follows the first byte
            // the string follows the length of the string
            let output = try longData(prefix: prefix, typeIdentifier: 0xb7, input: input, offset: &offset)
            return output

        case 0xc0...0xf7:
            // if the range of the first byte is [0xc0, 0xf7] then the data is a list
            // the length of the payload is the first byte minus 0xc0
            // the payload is equal to the concatenation of the RLP encodings of all items of the list follows the first byte
            let payload = try shortData(prefix: prefix, typeIdentifier: 0xc0, input: input, offset: &offset)
            let output = try array(payload: payload)
            return output

        case 0xf8...0xff:
            // if the range of the first byte is [0xf8, 0xff] then the data is a list
            // the length of encoded list length is equal to the first byte minus 0xf7
            // the length of payload is encoded binary integer follows the first byte
            // the payload is equal to the concatenation of the RLP encodings of all items of the list follows the encoded length of the list
            let payload = try longData(prefix: prefix, typeIdentifier: 0xf7, input: input, offset: &offset)
            let output = try array(payload: payload)
            return output

        default:
            throw RlpDecodingError.notRlpEncoded
        }
    }

    internal func subdata(startIndex: Int, length: Int, data: Data) throws -> (payload: Data, endIndex: Int) {
        let endIndex = length + startIndex

        guard endIndex <= data.count else {
            throw RlpDecodingError.offsetOutOfBounds
        }

        let payload = data.subdata(in: startIndex..<endIndex)
        return (payload, endIndex)
    }

    internal func shortData(prefix: UInt8, typeIdentifier: Int, input: Data, offset: inout Int) throws -> Data {
        let payload: Data
        (payload, offset) = try subdata(startIndex: 1, length: Int(prefix) - typeIdentifier, data: input)
        return payload
    }

    internal func longData(prefix: UInt8, typeIdentifier: Int, input: Data, offset: inout Int) throws -> Data {
        let (lengthPayload, lengthEndIndex) = try subdata(startIndex: 1, length: Int(prefix) - typeIdentifier, data: input)
        let payloadLength: UInt64 = try decode(integer: lengthPayload)

        let payload: Data
        (payload, offset) = try subdata(startIndex: lengthEndIndex, length: Int(payloadLength), data: input)
        return payload
    }

    internal func array(payload: Data) throws -> [RlpCodable] {
        var items = [RlpCodable]()
        var payloadOffset = 0
        while payloadOffset < payload.count {
            let itemPayload = payload.subdata(in: payloadOffset..<payload.count)
            var itemPayloadOffset = 0
            let item = try decode(itemPayload, offset: &itemPayloadOffset)
            payloadOffset += itemPayloadOffset
            items.append(item)
        }
        return items
    }

    public struct RlpDecodingError: Error {
        public var code: Int
        public var message: String

        public static let inputIsNull = RlpDecodingError(code: -1, message: "input is null")
        public static let integerTooBig = RlpDecodingError(code: -2, message: "integer data does not fit to bit width")
        public static let notRlpEncoded = RlpDecodingError(code: -3, message: "input doesn't conform to RLP encoding form")
        public static let offsetOutOfBounds = RlpDecodingError(code: -4, message: "data offset is out of bounds")
    }
}
