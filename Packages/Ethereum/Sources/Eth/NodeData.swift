//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

public protocol NodeDataCodable {
    init()
    init(decoding data: Data) throws
    func encodeNodeData() throws -> Data
}

public struct NodeData<T> where T: NodeDataCodable {
    public var value: T

    public init() {
        self.init(.init())
    }

    public init(_ value: T) {
        self.value = value
    }
}

extension NodeData: Codable {
    //    A Data value MUST be hex-encoded.
    //    A Data value MUST be “0x”-prefixed.
    //    A Data value MUST be expressed using two hex digits per byte.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var string = try container.decode(String.self)

        guard string.hasPrefix("0x") else {
            throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                            debugDescription: "Data value MUST be 0x-prefixed",
                            underlyingError: nil)
            )
        }

        string.removeFirst(2)

        guard string.count % 2 == 0 else {
            throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                            debugDescription: "Data value MUST  be expressed using two hex digits per byte.",
                            underlyingError: nil)
            )
        }

        let hexDigitsPerByte = 2

        // we modify indexes in place to speed up the performance.
        // previous implementation that used offset from the start index had O(n^2) complexity
        // and was slow at non-trivial data chunks.
        let end = string.endIndex
        var indexStart = string.startIndex
        var indexEnd = string.index(indexStart, offsetBy: hexDigitsPerByte, limitedBy: end)
        let byteStrings = stride(from: 0, to: string.count, by: hexDigitsPerByte).map { offset -> String in
            let substring = string[indexStart..<indexEnd!]
            _ = string.formIndex(&indexStart, offsetBy: hexDigitsPerByte, limitedBy: end)
            _ = string.formIndex(&indexEnd!, offsetBy: hexDigitsPerByte, limitedBy: end)
            return String(substring)
        }
        let bytes = try byteStrings.map { string -> UInt8 in
            guard let byte = UInt8(string, radix: 16) else {
                throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: decoder.codingPath,
                                debugDescription: "Data value MUST be hex-encoded",
                                underlyingError: nil)
                )
            }
            return byte
        }

        let data = Data(bytes)
        let value = try T.init(decoding: data)
        self.init(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex())
    }

    public func hex() throws -> String {
        let data = try value.encodeNodeData()
        let result = "0x" + data.compactMap { String(format: "%02x", Int($0)) }.joined()
        return result
    }
}

extension NodeData: CustomStringConvertible {
    public var description: String {
        let result = try? hex()
        return result ?? "<error hex encoding>"
    }
}
