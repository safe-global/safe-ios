//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

class Contract {

    private(set) var address: Address
    private(set) var rpcURL: URL

    var nodeService: EthereumNodeService { App.shared.nodeService }

    init(_ address: Address, rpcURL: URL) {
        self.address = address
        self.rpcURL = rpcURL
    }

    convenience init(rpcURL: URL) {
        self.init(.zero, rpcURL: rpcURL)
    }

    func method(_ selector: String) -> Data {
        return EthHasher.hash(selector.data(using: .ascii)!).prefix(4)
    }

    func encodeUInt(_ value: Int) -> Data {
        return encodeUInt(UInt256(value))
    }

    func encodeUInt(_ value: Int256) -> Data {
        return encodeUInt(UInt256(value))
    }

    func encodeUInt(_ value: UInt256) -> Data {
        return Data(ethHex: String(value, radix: 16)).leftPadded(to: 32).suffix(32)
    }

    func decodeUInt(_ value: Data) -> UInt256 {
        let bigEndianValue = value.count > 32 ? value.prefix(32) : value
        return UInt256(bigEndianValue)
    }

    /// NOTE: resulting address is NOT formatted according to EIP-55
    func decodeAddress(_ value: Data) -> Address {
        let uintValue = decodeUInt(value)
        return Address(exactly: uintValue)
    }

    func encodeAddress(_ value: Address) -> Data {
        return encodeUInt(UInt256(value.data))
    }

    func decodeArrayUInt(_ value: Data) -> [UInt256] {
        if value.isEmpty { return [] }
        let offset = decodeUInt(value)
        guard offset < value.count else { return [] }
        let data = value.suffix(from: Int(offset))
        let count = decodeUInt(data)
        // 1 for the 'count' value itself + <count> number of items, each 32 bytes long
        guard (1 + count) * 32 >= data.count else { return [] }
        return decodeTupleUInt(data.suffix(from: data.startIndex + 32), Int(count))
    }

    func encodeArrayUInt(_ value: [UInt256]) -> Data {
        return encodeUInt(32) + encodeUInt(UInt256(value.count)) + encodeTupleUInt(value)
    }

    func encodeArrayAddress(_ value: [Address]) -> Data {
        return encodeArrayUInt(value.map { UInt256($0.data) })
    }

    func decodeArrayAddress(_ value: Data) -> [Address] {
        return decodeArrayUInt(value).map { Address(exactly: $0) }
    }

    func decodeTupleUInt(_ value: Data, _ count: Int) -> [UInt256] {
        if value.count < count * 32 { return [] }
        let rawValues = stride(from: value.startIndex, to: value.startIndex + count * 32, by: 32).map { i in
            value[i..<i + 32]
        }
        return rawValues.compactMap { decodeUInt($0) }
    }

    func encodeTupleUInt(_ value: [UInt256]) -> Data {
        return (value.map { headUInt($0) } + value.map { tailUInt($0) }).reduce(into: Data()) { $0.append($1) }
    }

    func headUInt(_ value: UInt256) -> Data {
        return encodeUInt(value)
    }

    func tailUInt(_ value: UInt256) -> Data {
        return Data()
    }

    func encodeBool(_ value: Bool) -> Data {
        return encodeUInt(value ? 1 : 0)
    }

    func decodeBool(_ value: Data) -> Bool {
        return decodeUInt(value) == 0 ? false : true
    }

    func encodeFixedBytes(_ value: Data) -> Data {
        return value.rightPadded(to: 32).prefix(32)
    }

    func decodeFixedBytes(value: Data, size: Int) -> Data {
        return value.prefix(size)
    }

    func encodeBytes(_ value: Data) -> Data {
        let byteLength = value.count % 32 == 0 ? value.count :
            (value.count + 32 - value.count % 32)
        return encodeUInt(UInt256(value.count)) +
            value.rightPadded(to: byteLength)
    }

    func decodeBytes(_ value: Data) -> Data {
        var encoded = value
        let count = decodeUInt(encoded)
        encoded = encoded.dropFirst(32)
        return encoded.prefix(Int(count))
    }

    func decodeString(_ value: Data) -> String? {
        guard value.count > 64 else { return nil } // 32 bytes for offset, 32 bytes for byte count
        var encoded = value
        let offset = decodeUInt(encoded); encoded.removeFirst(32)
        let bytes = decodeBytes(value.advanced(by: Int(offset)))
        let result = String(data: bytes, encoding: .utf8)
        return result
    }

    func invoke(_ selector: String, _ args: Data ...) throws -> Data {
        return try nodeService.eth_call(to: address, rpcURL: rpcURL, data: invocation(selector, args: args))
    }

    func invoke(_ selector: String, args: [Data]) throws -> Data {
        return try nodeService.eth_call(to: address, rpcURL: rpcURL, data: invocation(selector, args: args))
    }

    func invocation(_ selector: String, _ args: Data ...) -> Data {
        return invocation(selector, args: args)
    }

    func invocation(_ selector: String, args: [Data]) -> Data {
        return method(selector) + args.reduce(into: Data()) { $0.append($1) }
    }
}

