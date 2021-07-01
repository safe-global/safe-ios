//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ContractTests: XCTestCase {

    let contract = Contract(.zero, rpcURL: URL(string: "https://example.com")!)

    func test_selectorToMethodId() {
        let selector = "abc()".data(using: .ascii)!
        let expectedHash = EthHasher.hash(selector)
        let methodCall = expectedHash.prefix(4)
        XCTAssertEqual(contract.method("abc()"), methodCall)
    }

    func test_whenEncodingUInt_thenEncodesInto32Bytes() {
        let rawValue = Data(repeating: 0, count: 32 - 160 / 8) + Data(repeating: 0xff, count: 160 / 8)
        let expectedValue = UInt256(2).power(160) - 1
        XCTAssertEqual(contract.encodeUInt(expectedValue), rawValue)
    }

    func test_whenEncodingUIntTooBig_thenTakesRightmost32Bytes() {
        let tooBig = UInt256(2).power(512) - 1
        let remainder = UInt256(2).power(256) - 1
        XCTAssertEqual(contract.encodeUInt(tooBig), contract.encodeUInt(remainder))
    }

    func test_whenDecodingUInt160_thenDecodesAsBigInt() {
        let expectedValue = UInt256(2).power(160) - 1
        XCTAssertEqual(contract.decodeUInt(contract.encodeUInt(expectedValue)), expectedValue)
    }
    func test_whenDecodingUIntEmptyData_thenReturns0() {
        XCTAssertEqual(contract.decodeUInt(Data()), 0)
    }

    func test_whenEncodingTupleUInt_thenEncodesToData() {
        let values = (0..<3).map { i in UInt256(2) ^ (1 + i) }
        let rawValues = values.map { contract.encodeUInt($0) }.reduce(into: Data()) { $0.append($1) }
        XCTAssertEqual(rawValues.count, 3 * 32)

        XCTAssertEqual(contract.encodeTupleUInt(values), rawValues)
    }

    func test_whenDataIsEmpty_thenDecodingReturnsEmptyValue() {
        XCTAssertEqual(contract.decodeArrayAddress(Data()), [])
        XCTAssertEqual(contract.decodeArrayUInt(Data()), [])
        XCTAssertEqual(contract.decodeTupleUInt(Data(), 0), [])
        XCTAssertEqual(contract.decodeTupleUInt(Data(), 1), [])
    }

    func test_whenDecodingTupleOfStaticTypes_thenDecodesAsArray() {
        let values = (0..<3).map { i in UInt256(2) ^ (1 + i) }
        XCTAssertEqual(contract.decodeTupleUInt(contract.encodeTupleUInt(values), values.count), values)
    }

    func test_whenEncodingArrayUInt_thenEncodesToData() {
        let values = (0..<3).map { i in UInt256(2) ^ (1 + i) }
        let offsetToData = contract.encodeUInt(32)
        let count = contract.encodeUInt(3)
        let items = values.map { contract.encodeUInt($0) }.reduce(into: Data()) { $0.append($1) }
        let rawValues = offsetToData + count + items
        XCTAssertEqual(contract.encodeArrayUInt(values), rawValues)
    }

    func test_whenDecodingArrayOfUInts_thenReturnsArray() {
        let values = [UInt256(1), UInt256(2), UInt256(3)]
        XCTAssertEqual(contract.decodeArrayUInt(contract.encodeArrayUInt(values)), values)
    }

    func test_whenEncodesDecodesAddress_thenUsesUInt() {
        let values = [Address(exactly: 1), Address(exactly: 2)]
        let uints: [UInt256] = [1, 2]
        XCTAssertEqual(contract.encodeArrayAddress(values), contract.encodeArrayUInt(uints))
    }

    func test_whenDecodesAddress_thenReturnsIt() {
        let rawValue = contract.encodeUInt(1)
        XCTAssertEqual(contract.decodeAddress(rawValue), Address(exactly: 1))
    }

    func test_whenEncodesAddress_thenReturnsData() {
        XCTAssertEqual(contract.encodeAddress(Address(exactly: 1)), contract.encodeUInt(1))
    }

    func test_whenEncodesDecodesBool_thenDoesItCorrectly() {
        XCTAssertEqual(contract.encodeBool(true), contract.encodeUInt(1))
        XCTAssertEqual(contract.encodeBool(false), contract.encodeUInt(0))
        XCTAssertEqual(contract.decodeBool(Data()), false)
        XCTAssertEqual(contract.decodeBool(contract.encodeUInt(123)), true)
        XCTAssertEqual(contract.decodeBool(contract.encodeUInt(1)), true)
        XCTAssertEqual(contract.decodeBool(contract.encodeUInt(0)), false)
    }

    func test_encodeBytes() {
        let shorterThan32Bytes = Data([0x01])
        let exactly32Bytes = Data(repeating: 0xa, count: 32)
        let multipleOf32Bytes = Data(repeating: 0xb, count: 64)
        let remainderShorterThan32Bytes = Data(repeating: 0xc, count: 33)

        XCTAssertEqual(contract.encodeBytes(shorterThan32Bytes),
                       contract.encodeUInt(UInt256(shorterThan32Bytes.count)) +
                       shorterThan32Bytes.rightPadded(to: 32))

        XCTAssertEqual(contract.encodeBytes(exactly32Bytes),
                       contract.encodeUInt(UInt256(exactly32Bytes.count)) +
                       exactly32Bytes)

        XCTAssertEqual(contract.encodeBytes(multipleOf32Bytes),
                       contract.encodeUInt(UInt256(multipleOf32Bytes.count)) +
                       multipleOf32Bytes)

        XCTAssertEqual(contract.encodeBytes(remainderShorterThan32Bytes),
                       contract.encodeUInt(UInt256(remainderShorterThan32Bytes.count)) +
                       remainderShorterThan32Bytes.rightPadded(to: 64))

        XCTAssertEqual(contract.decodeBytes(contract.encodeBytes(shorterThan32Bytes)), shorterThan32Bytes)
        XCTAssertEqual(contract.decodeBytes(contract.encodeBytes(exactly32Bytes)), exactly32Bytes)
        XCTAssertEqual(contract.decodeBytes(contract.encodeBytes(multipleOf32Bytes)), multipleOf32Bytes)
        XCTAssertEqual(contract.decodeBytes(contract.encodeBytes(remainderShorterThan32Bytes)), remainderShorterThan32Bytes)

    }

}
