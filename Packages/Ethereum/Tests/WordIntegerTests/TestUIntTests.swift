//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 25.12.21.
//

import Foundation
import XCTest
import WordInteger
import BigInt

class TestUIntTests: XCTestCase {
    typealias u200 = TestUInt200
    func testInit() {
        let empty = u200(storage: [])
        XCTAssertEqual(empty, 0)

        let notEnough = u200(storage: [UInt](repeating: .max, count: 1))
        XCTAssertEqual(notEnough, 0xffff_ffff_ffff_ffff)

        let enough = u200(storage: [UInt](repeating: .max, count: 200 / UInt.bitWidth + 1))
        XCTAssertEqual(enough, "1606938044258990275541962092341162602522202993782792835301375")

        let moreEnough = u200(storage: [UInt](repeating: .max, count: 9))
        XCTAssertEqual(moreEnough, "1606938044258990275541962092341162602522202993782792835301375")
    }

    func testComparable() {
        let a: u200 = 0
        let b: u200 = 1
        XCTAssertLessThan(a, b)
    }

    func testInvert() {
        let z: u200 = 1
        let minusZ: u200 = "1606938044258990275541962092341162602522202993782792835301374"
        XCTAssertEqual(~z, minusZ)
    }

    func testAdd() {
        assert(1, +, 2, 3)
        assert(0, +, 0, 0)
        assert(0, +, 1, 1)
        assert(1, +, 0, 1)
        assert(0, +, .max, .max)
        assert("1606938044258990275541962092341162602522202993782792835301374", +, 1, "1606938044258990275541962092341162602522202993782792835301375")
    }

    func testSubtract() {
        assert(1, -, 1, 0)
        assert(7, -, 4, 3)
    }

    func testAddOverflow() {
        assert("1606938044258990275541962092341162602522202993782792835301375", u200.addingReportingOverflow(_:), 1, (0, true))
    }

    func testSubtractOverflow() {
        assert(0, u200.subtractingReportingOverflow(_:), 1, ("1606938044258990275541962092341162602522202993782792835301375", true))
    }

    func assert(_ a: u200, _ op: (u200, u200) -> u200, _ b: u200, _ c: u200, line: UInt = #line) {
        XCTAssertEqual(op(a, b), c, line: line)
    }

    func assert(_ a: u200, _ op: (u200) -> (u200) -> (u200, Bool), _ b: u200, _ c: (u200, Bool), line: UInt = #line) {
        let result = op(a)(b)
        XCTAssertEqual(result.0, c.0, line: line)
        XCTAssertEqual(result.1, c.1, line: line)
    }

    func testBitCounts() {
        XCTAssertEqual(u200(0).nonzeroBitCount, 0)
        XCTAssertEqual(u200(1).nonzeroBitCount, 1)
        XCTAssertEqual(u200.max.nonzeroBitCount, 200)

        XCTAssertEqual(u200(0).leadingZeroBitCount, 200)
        XCTAssertEqual(u200(1).leadingZeroBitCount, 199)
        XCTAssertEqual(u200(31).leadingZeroBitCount, 195)
        XCTAssertEqual(u200.max.leadingZeroBitCount, 0)

        XCTAssertEqual(u200(0).trailingZeroBitCount, 200)
        XCTAssertEqual(u200(1).trailingZeroBitCount, 0)
        XCTAssertEqual(u200(2).trailingZeroBitCount, 1)
        XCTAssertEqual(u200("1606938044258990275541962092341162602522202993782792835301368").trailingZeroBitCount, 3)
    }

    func testDivideFullWidth() {
        // u200.max = 2^200 - 1
        // (1, 0) = 2^200
        // 2^200 / 2 = 2^199
        let dividend = (u200(1), u200(0))
        let divisor = u200(2)
        let (q, r) = divisor.dividingFullWidth(dividend)
        XCTAssertEqual(q, u200("803469022129495137770981046170581301261101496891396417650688"))
        XCTAssertEqual(r, u200(0))
    }

    func testByteSwap() {
        XCTAssertEqual(u200(1).byteSwapped, "6277101735386680763835789423207666416102355444464034512896")
    }

    func testSign() {
        XCTAssertEqual(u200(3).signum(), 1)
    }

    func testInitExactlyFromSource() {
        let max = TestUInt201.max
        XCTAssertNil(u200(exactly: max))
        XCTAssertNotNil(u200(exactly: 5))
    }

    func testAlgo() {
        XCTAssertEqual(log2(u200(1024)), 10)
        XCTAssertEqual(log2(u200(1_048_576)), 20)
        XCTAssertEqual(pow(u200(10), 1), 10)
        XCTAssertEqual(pow(u200(10), 0), 1)
        XCTAssertEqual(pow(u200(10), 25), u200("10000000000000000000000000"))
        XCTAssertEqual(log10(u200("10000000000000000000000000")), 25)
        XCTAssertEqual(log10(u200("10000000000000000000000000")), 25)
        XCTAssertEqual(log10(u200("1606938044258990275541962092341162602522202993782792835301375")), 60)
        XCTAssertEqual(log2(u200("1606938044258990275541962092341162602522202993782792835301375")), 199)
    }

    func testExactlyBig() {
        // max = 2^n - 1 = 2^200 - 1 = 1606938044258990275541962092341162602522202993782792835301375
        XCTAssertNil(u200(exactlyBig: "1606938044258990275541962092341162602522202993782792835301376"))
        XCTAssertNotNil(u200(exactlyBig: "1606938044258990275541962092341162602522202993782792835301375"))
    }

}


public struct TestUInt200 {
    public var storage: [UInt]

    public init() { storage = [] }
}


// required by TestUInt200.Strideable.Stride (and FixedWidthInteger.Stride constraints)
public struct TestInt200 {
    public var storage: [UInt]

    public init() { storage = [] }
}

extension TestUInt200: WordUnsignedInteger {
    public typealias Stride = TestInt200
    public typealias Magnitude = TestUInt200
    public typealias IntegerLiteralType = UInt

    public static var bitWidth: Int { 200 }
}

extension TestInt200: WordSignedInteger {
    public typealias Stride = TestInt200
    public typealias Magnitude = TestUInt200
    public typealias IntegerLiteralType = Int

    public static var bitWidth: Int { 200 }
}

public struct TestUInt201: WordUnsignedInteger {
    public typealias Stride = TestInt201
    public typealias Magnitude = TestUInt201
    public typealias IntegerLiteralType = UInt

    public static var bitWidth: Int { 201 }

    public var storage: [UInt]

    public init() { storage = [] }
}

public struct TestInt201: WordSignedInteger {
    public typealias Stride = TestInt201
    public typealias Magnitude = TestUInt201
    public typealias IntegerLiteralType = Int

    public static var bitWidth: Int { 201 }

    public var storage: [UInt]

    public init() { storage = [] }
}
