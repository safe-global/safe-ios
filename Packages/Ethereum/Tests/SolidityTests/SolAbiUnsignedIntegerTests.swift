//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 22.12.21.
//

import Foundation
@testable import Solidity
import XCTest
import BigInt

class UInt256Tests: XCTestCase {
    typealias u256 = SolAbi.UInt256

    let low = u256(0)
    let low_plus_1 = u256(1)

    let half_minus_1 = u256(store: BigUInt(2).power(u256.bitWidth - 1) - 1)
    let half = u256(store: BigUInt(2).power(u256.bitWidth - 1))
    let half_plus_1 = u256(store: BigUInt(2).power(u256.bitWidth - 1) + 1)

    let high_minus_1 = u256(store: BigUInt(2).power(u256.bitWidth) - 2)
    let high = u256(store: BigUInt(2).power(u256.bitWidth) - 1)

    func testMax() {
        XCTAssertEqual(u256.max.store, BigUInt(2).power(u256.bitWidth) - 1)
    }

    func testWords() {
        XCTAssertEqual(low.words, [0, 0, 0, 0])
        XCTAssertEqual(u256(1).words, [1, 0, 0, 0])
        XCTAssertEqual(u256.max.words, [UInt.max, UInt.max, UInt.max, UInt.max])
        XCTAssertEqual((u256.max - 1).words, [UInt.max - 1, UInt.max, UInt.max, UInt.max])
    }

    func testTrailingZeroBitCount() {
        XCTAssertEqual(u256(0).trailingZeroBitCount, 256)
        XCTAssertEqual(u256(0b10).trailingZeroBitCount, 1)
        XCTAssertEqual(u256.max.trailingZeroBitCount, 0)
        XCTAssertEqual(u256("8000000000000000000000000000000000000000000000000000000000000000", radix: 16)!.trailingZeroBitCount, 255)
        XCTAssertEqual(u256("c000000000000000000000000000000000000000000000000000000000000000", radix: 16)!.trailingZeroBitCount, 254)
    }

    func testNonZeroBitCount() {
        XCTAssertEqual(u256(0).nonzeroBitCount, 0)
        XCTAssertEqual(u256.max.nonzeroBitCount, 256)
        XCTAssertEqual(u256(1).nonzeroBitCount, 1)
        XCTAssertEqual((u256.max - 1).nonzeroBitCount, 255)
        XCTAssertEqual((u256.max - 2).nonzeroBitCount, 255)
        XCTAssertEqual((u256.max - 3).nonzeroBitCount, 254)
    }

    func testLeadingZeroBitCount() {
        XCTAssertEqual(u256(0).leadingZeroBitCount, 256)
        XCTAssertEqual(u256.max.leadingZeroBitCount, 0)
        XCTAssertEqual(u256(1).leadingZeroBitCount, 255)
        XCTAssertEqual((u256.max - 1).leadingZeroBitCount, 0)
        XCTAssertEqual(u256("7000000000000000000000000000000000000000000000000000000000000000", radix: 16)!.leadingZeroBitCount, 1)
        XCTAssertEqual(u256("3000000000000000000000000000000000000000000000000000000000000000", radix: 16)!.leadingZeroBitCount, 2)
    }

    func testByteSwapped() {
        XCTAssertEqual(u256(0).byteSwapped, u256(0))
        XCTAssertEqual(u256(1).byteSwapped, u256("100000000000000000000000000000000000000000000000000000000000000", radix: 16)!)
        XCTAssertEqual(u256.max.byteSwapped, u256.max)
        XCTAssertEqual((u256.max - 1).byteSwapped, u256("feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16)!)
    }

    func testRequiredWordCount() {
        XCTAssertEqual(u256.requiredWordCount, 4)
    }

    func testDescription() {
        XCTAssertEqual(u256(0).description, "0")
        XCTAssertEqual(u256(1).description, "1")
        XCTAssertEqual(u256.max.description, "115792089237316195423570985008687907853269984665640564039457584007913129639935")
        XCTAssertEqual((u256.max - 1).description, "115792089237316195423570985008687907853269984665640564039457584007913129639934")
    }

    func testPlaygroundDescription() {
        XCTAssertEqual(u256(0).playgroundDescription as? String, "0 (0 bits)")
        XCTAssertEqual(u256(1).playgroundDescription as? String, "1 (1 bits)")
        XCTAssertEqual(u256.max.playgroundDescription as? String, "115792089237316195423570985008687907853269984665640564039457584007913129639935 (256 bits)")
        XCTAssertEqual((u256.max - 1).playgroundDescription as? String, "115792089237316195423570985008687907853269984665640564039457584007913129639934 (256 bits)")
    }

    func testInitWithBigUint() {
        let _2expN = BigUInt(2).power(u256.bitWidth)

        XCTAssertEqual(u256(store: _2expN - 1).store, _2expN - 1)
        XCTAssertEqual(u256(store: _2expN - 2).store, _2expN - 2)

        XCTAssertEqual(u256(store: _2expN).store, 0)
        XCTAssertEqual(u256(store: 0).store, 0)
        XCTAssertEqual(u256(store: 1).store, 1)
        XCTAssertEqual(u256(store: _2expN / 4).store, _2expN / 4)
    }

    func testAddWithOverflow() {
        // (0, 2^256), (0, 2^256)

        // 0 + 0 = 0
        assertEqual(low.addingReportingOverflow(low), (0 , false))

        // 1 + 1 = 2

        assertEqual(low_plus_1.addingReportingOverflow(low_plus_1), (2, false))

        // 0 + 1 = 1
        assertEqual(low.addingReportingOverflow(low_plus_1), (1, false))

        // 1 + 0 = 1
        assertEqual((low_plus_1).addingReportingOverflow(low), (1, false))

        // 0 + 2^256-1
        assertEqual(low.addingReportingOverflow(high), (high, false))
        // 0 + 2^256-2


        assertEqual(low.addingReportingOverflow(high_minus_1), (high_minus_1, false))

        // 2^256-1 + 0
        assertEqual((high).addingReportingOverflow(low), (high, false))
        // 2^256-2 + 0
        assertEqual((high_minus_1).addingReportingOverflow(low), (high_minus_1, false))

        // 1 + 2^256-1 = 2^256
        assertEqual((low_plus_1).addingReportingOverflow(high), (0, true))

        // 1 + 2^256-2 = 2^256-1
        assertEqual((low_plus_1).addingReportingOverflow(high_minus_1), (high, false))

        // 2^256-1 + 1 = 2^256
        assertEqual((high).addingReportingOverflow(low_plus_1), (0, true))

        // 2^256-2 + 1 = 2^256-1
        assertEqual((high_minus_1).addingReportingOverflow(low_plus_1), (high, false))

        // 2^255 + 2^255 = 2^256
        assertEqual(half.addingReportingOverflow(half), (0, true))

        // 2^255-1 + 2^255 = 2^256-1
        assertEqual((half_minus_1).addingReportingOverflow(half), (high, false))

        // 2^255 + 2^255-1 = 2^256-1
        assertEqual(half.addingReportingOverflow(half_minus_1), (high, false))

        // 2^255+1 + 2^255+1 = 2^256+2
        assertEqual(half_plus_1.addingReportingOverflow(half_plus_1), (2, true))

        // 2^255 + 2^255+1 = 2^256+1
        assertEqual(half.addingReportingOverflow(half_plus_1), (1, true))

        // 2^254+1 + 2^254 = 2^256+1
        assertEqual(half_plus_1.addingReportingOverflow(half), (1, true))

        // 2^256-1 + 2^256-1 = 2^257 - 2 = truncated 2^256 - 2
        assertEqual(high.addingReportingOverflow(high), (high_minus_1, true))
    }

    func testOnesComplement() {
        XCTAssertEqual(low.onesComplement, high)
        XCTAssertEqual(u256(1).onesComplement, high - 1)
        XCTAssertEqual(high.onesComplement, low)
        XCTAssertEqual((high - 1).onesComplement, u256(1))
    }

    func testTwosComplement() {
        XCTAssertEqual(low.twosComplement, 0)
        XCTAssertEqual(u256(1).twosComplement, high)
        XCTAssertEqual(high.twosComplement, u256(1))
        XCTAssertEqual((high - 1).twosComplement, u256(2))
    }

    func testSubtractWithOverflow() {

        // 0 - 0 = 0
        assertEqual(low.subtractingReportingOverflow(low), (0, false))

        // 0 - 1 = (max, t)
        assertEqual(low.subtractingReportingOverflow(low_plus_1), (high, true))

        // 1 - 0 = 1
        assertEqual(low_plus_1.subtractingReportingOverflow(low), (1, false))

        // 1 - 1 = 0
        assertEqual(low_plus_1.subtractingReportingOverflow(low_plus_1), (0, false))

        // 2^256-1 - 2^256-1 = 0
        assertEqual(high.subtractingReportingOverflow(high), (0, false))

        // 2^256-2 - 2^256-1 = (max, t)
        assertEqual(high_minus_1.subtractingReportingOverflow(high), (high, true))

        // 2^256-1 - 2^256-2 = 1
        assertEqual(high.subtractingReportingOverflow(high_minus_1), (1, false))

        // 2^256-2 - 2^256-2 = 0
        assertEqual(high_minus_1.subtractingReportingOverflow(high_minus_1), (0, false))

        // 0 - 2^256-1 = (1, t)
        assertEqual(low.subtractingReportingOverflow(high), (1, true))

        // 2^256-1 - 0 = 2^256-1
        assertEqual(high.subtractingReportingOverflow(low), (high, false))

        // 0 - 2^256-2 = (2, t)
        assertEqual(low.subtractingReportingOverflow(high_minus_1), (2, true))

        // 2^256-2 - 0 = 2^256-2
        assertEqual(high_minus_1.subtractingReportingOverflow(low), (high_minus_1, false))
    }

    func testMultiplyWithOverflow() {
        // 0 * max = 0, f
        assertEqual(low.multipliedReportingOverflow(by: high), (low, false))
        // 1 * max = max, f
        assertEqual(low_plus_1.multipliedReportingOverflow(by: high), (high, false))
        // 2 * max = max-1, t
        assertEqual(u256(2).multipliedReportingOverflow(by: high), (high_minus_1, true))
        // 4 * max = max-1, t
        // 2^2 * (2^256 - 1) = 2^256 * 2^2 - 2^2
        assertEqual(u256(4).multipliedReportingOverflow(by: high), (u256(store: BigUInt(2).power(u256.bitWidth) - 4), true))
    }

    func testDividedOverflow() {
        // 1 / 2 = 0, f
        assertEqual(u256(1).dividedReportingOverflow(by: u256(2)), (0, false))
        // 2 / 1 = 2, f
        assertEqual(u256(2).dividedReportingOverflow(by: u256(1)), (2, false))
        // max / 1 = max, f
        assertEqual(high.dividedReportingOverflow(by: u256(1)), (high, false))
        // (2^256 - 1) / 2 = 2^255-1
        assertEqual(high.dividedReportingOverflow(by: u256(2)), (half_minus_1, false))
        // max / 0 = max, t
        assertEqual(high.dividedReportingOverflow(by: u256(0)), (high, true))
    }

    func testRemainderOverflow() {
        // 1 % 2 = 1, f
        assertEqual(u256(1).remainderReportingOverflow(dividingBy: u256(2)), (1, false))

        // 2 % 1 = 0, f
        assertEqual(u256(2).remainderReportingOverflow(dividingBy: u256(1)), (0, false))

        // max % 2 = 1, f
        assertEqual(high.remainderReportingOverflow(dividingBy: u256(2)), (1, false))

        // max % 0 = max, t
        assertEqual(high.remainderReportingOverflow(dividingBy: u256(0)), (high, true))
    }

    func testDivideFullWidth() {
        // 2 * (2^256-1) = 2^257-2 = (1, 2^256-2)
        assertEqual(u256(2).dividingFullWidth((u256(1), high_minus_1)), (high, 0))
    }

    func testXor() {
        XCTAssertEqual(u256(0) ^ u256.max, u256.max)
        XCTAssertEqual(u256.max ^ u256(0), u256.max)
        XCTAssertEqual(u256(0) ^ u256(0), u256(0))
        XCTAssertEqual(u256.max ^ u256.max, u256(0))
    }

    func testXorEquals() {
        var a = u256.max
        a ^= u256.max
        XCTAssertEqual(a, 0)
    }

    func testAnd() {
        XCTAssertEqual(u256(0) & u256.max, u256(0))
        XCTAssertEqual(u256.max & u256(0), u256(0))
        XCTAssertEqual(u256(0) & u256(0), u256(0))
        XCTAssertEqual(u256.max & u256.max, u256.max)
    }

    func testAndEquals() {
        var a = u256.max
        a &= 0
        XCTAssertEqual(a, 0)
    }

    func testOr() {
        XCTAssertEqual(u256(0) | u256.max, u256.max)
        XCTAssertEqual(u256.max | u256(0), u256.max)
        XCTAssertEqual(u256(0) | u256(0), u256(0))
        XCTAssertEqual(u256.max & u256.max, u256.max)
    }

    func testOrEquals() {
        var a = u256.max
        a |= 0
        XCTAssertEqual(a, u256.max)
    }

    func testTimes() {
        // 2^255-1 * 2 = 2^256 - 2
        XCTAssertEqual(u256(2) * half_minus_1, high_minus_1)
    }

    func testTimesEquals() {
        var a = half_minus_1
        a *= 2
        XCTAssertEqual(a, high_minus_1)
    }

    func testDivide() {
        XCTAssertEqual(high_minus_1 / 2, half_minus_1)
    }

    func testDivideEquals() {
        var a = high_minus_1
        a /= 2
        XCTAssertEqual(a, half_minus_1)
    }

    func testModulo() {
        XCTAssertEqual(high % 2, 1)
    }

    func testModuloEquals() {
        var a = high
        a %= 2
        XCTAssertEqual(a, 1)
    }

    func testLess() {
        XCTAssertLessThan(low, low_plus_1)
        XCTAssertLessThan(high_minus_1, high)
        XCTAssertLessThan(low, high)
        XCTAssertGreaterThanOrEqual(high, high)
        XCTAssertGreaterThan(high, high_minus_1)
    }

    func testRightShift() {
        XCTAssertEqual(u256(30) >> 2, u256(7))
        XCTAssertEqual(u256(30) >> 257, 0)
        XCTAssertEqual(u256(high) >> 1, half_minus_1)
        XCTAssertEqual(u256(30) >> -3, 240)
        XCTAssertEqual(u256(30) << 3, 240)
    }

    func testLeftShift() {
        XCTAssertEqual(u256(30) << 2, u256(120))
        XCTAssertEqual(u256(30) << 257, 0)
        XCTAssertEqual(u256(half_minus_1) << 1, high_minus_1)
        XCTAssertEqual(u256(30) << -3, 3)
    }

    func testEncodeAbi() {
        XCTAssertEqual(u256(0).encode(), Data(repeating: 0x00, count: 32))
        XCTAssertEqual(u256(1).encode(), Data(repeating: 0x00, count: 31) + Data([0x01]))
        XCTAssertEqual(u256.max.encode(), Data(repeating: 0xff, count: 32))
        XCTAssertEqual(high_minus_1.encode(), Data(repeating: 0xff, count: 31) + Data([0xfe]))
        XCTAssertEqual(half.encode(), Data([0x80]) + Data(repeating: 0, count: 31))
    }
}

class UInt72Tests: XCTestCase {
    typealias u72 = SolAbi.UInt72

    func testInversion() {
        let x = u72(store: BigUInt(2).power(72) - 1)
        XCTAssertEqual(~x, u72(0))
    }

    func testMax() {
        XCTAssertEqual(u72.max.store, BigUInt(2).power(72) - 1)
    }

    func testSmoke() {
        XCTAssertEqual(u72(store: BigUInt(2).power(64)) + 5, u72(store: BigUInt(2).power(64) + 5))
        XCTAssertEqual(u72.max ^ u72(0), u72.max)
        assertEqual(u72(0).subtractingReportingOverflow(u72(1)), (u72.max, true))

        XCTAssertEqual([UInt8](u72.max.encode()), [UInt8](Data(repeating: 0, count: 32 - 72/8) + Data(repeating: 0xff, count: 72/8)))
    }

    func testSwapped() {
        XCTAssertEqual(u72(store: BigUInt("aabbbbccccddddeeee", radix: 16)!).byteSwapped,
                       u72(store: BigUInt("eeeeddddccccbbbbaa", radix: 16)!))
    }
}

func assertEqual<T: Equatable>(_ lhs: (quotient: T, remainder: T), _ rhs: (quotient: T, remainder: T), line: UInt = #line) {
    XCTAssertEqual(lhs.quotient, rhs.quotient, line: line)
    XCTAssertEqual(lhs.remainder, rhs.remainder, line: line)
}

func assertEqual<T: Equatable>(_ lhs: (partialValue: T, overflow: Bool), _ rhs: (partialValue: T, overflow: Bool), line: UInt = #line) {
    XCTAssertEqual(lhs.partialValue, rhs.partialValue, line: line)
    XCTAssertEqual(lhs.overflow, rhs.overflow, line: line)
}
