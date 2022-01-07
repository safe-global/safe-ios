//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 05.01.22.
//

import Foundation
import Ethereum
import XCTest

class RlpTests: XCTestCase {
    func testEncodeDog() {
        let expected = [0x83] + "dog".unicodeScalars.map(UInt8.init(ascii:))
        let output = RlpCoder().encode("dog")
        XCTAssertEqual(Array(output), expected)
    }

    func testDecodeDog() throws {
        let expected = "dog"
        let data = Data([0x83] + expected.unicodeScalars.map(UInt8.init(ascii:)))

        let decoded = try RlpCoder().decode(prototype: String(), input: data)

        continueAfterFailure = false
        XCTAssertTrue(decoded is String)

        XCTAssertEqual(decoded as! String, expected)
    }

    func testEncodeCatDog() {
        let cat = "cat".unicodeScalars.map(UInt8.init(ascii:))
        let dog = "dog".unicodeScalars.map(UInt8.init(ascii:))
        let expected = [0xc8, 0x83] + cat + [0x83] + dog
        let output = RlpCoder().encode(["cat", "dog"])
        XCTAssertEqual(Array(output), expected)
    }

    func testEncodeEmptyString() {
        let expected = Data([0x80])
        let output = RlpCoder().encode(Data())
        XCTAssertEqual(Array(output), Array(expected))
    }

    func testEncodeEmptyList() {
        let expected = Data([0xc0])
        let output = RlpCoder().encode([Data]() as [RlpCodable])
        XCTAssertEqual(Array(output), Array(expected))
    }

    func testEncodeZero() {
        let expected = Data([0x80])
        let output = RlpCoder().encode(UInt64(0))
        XCTAssertEqual(Array(output), Array(expected))
    }

    func testEncodeIntegers() {
        XCTAssertEqual([0x00], Array(RlpCoder().encode(Data([0]))))
        XCTAssertEqual([0x0f], Array(RlpCoder().encode(UInt64(15))))
        XCTAssertEqual([0x82, 0x04, 0x00], Array(RlpCoder().encode(UInt64(1024))))
    }

    func testEncodeSetOfThreeArrays() {
        let empty = [Data]() as [RlpCodable]
        let one = [empty] as RlpCodable
        let two = [empty, one] as RlpCodable
        let set = [empty, one, two] as RlpCodable

        let expected = Data([0xc7, 0xc0, 0xc1, 0xc0, 0xc3, 0xc0, 0xc1, 0xc0])

        let output = RlpCoder().encode(set)

        XCTAssertEqual(Array(output), Array(expected))
    }

    func testDecodeSetOfThreeArrays() throws {
        let rlpEncodedData = Data([0xc7, 0xc0, 0xc1, 0xc0, 0xc3, 0xc0, 0xc1, 0xc0])

        let empty = [Data]() as [RlpCodable]
        let one = [empty] as RlpCodable
        let two = [empty, one] as RlpCodable
        let expected = [empty, one, two] as RlpCodable

        let output = try RlpCoder().decode(prototype: expected, input: rlpEncodedData)

        continueAfterFailure = true

        XCTAssertTrue(output is [RlpCodable])
        let out3 = output as! [RlpCodable]
        XCTAssertEqual(out3.count, 3)

        let out0 = out3[0] as! [Data]
        XCTAssertEqual(out0, empty as! [Data])

        let out1 = out3[1] as! [[Data]]
        XCTAssertEqual(out1[0], empty as! [Data])

        let out2 = out3[2] as! [RlpCodable]
        XCTAssertEqual(out2[0] as! [Data], empty as! [Data])
        XCTAssertEqual(out2[1] as! [[Data]], one as! [[Data]])
    }

    func testLipsum() {
        let str = "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        let expected = Data([0xb8, 0x38] + str.unicodeScalars.map(UInt8.init(ascii:)))
        let output = RlpCoder().encode(str)
        XCTAssertEqual(Array(output), Array(expected))
    }

    func testLongData() throws {
        let value = Data(repeating: 7, count: 56)
        let encoded = RlpCoder().encode(value)

        let decoded = try RlpCoder().decode(prototype: Data(), input: encoded) as! Data

        XCTAssertEqual(Array(decoded), Array(value))
    }

    func testLongArray() throws {
        let value = [Data](repeating: Data([7]), count: 56)
        let encoded = RlpCoder().encode(value as [RlpCodable])

        let decoded = try RlpCoder().decode(prototype: [Data()], input: encoded) as! [Data]

        XCTAssertEqual(decoded, value)
    }
}
