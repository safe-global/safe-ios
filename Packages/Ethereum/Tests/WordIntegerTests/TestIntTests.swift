//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 25.12.21.
//

import Foundation
import XCTest
import WordInteger

class TestIntTests: XCTestCase {
    typealias i200 = TestInt200

    func testInit() {
        let empty = i200(storage: [])
        XCTAssertEqual(empty, 0)

        let notEnough = i200(storage: [UInt](repeating: .max, count: 1))
        XCTAssertEqual(notEnough, -1)

        let enough = i200(storage: [UInt](repeating: .max, count: 200 / UInt.bitWidth + 1))
        XCTAssertEqual(enough, -1)

        let moreEnough = i200(storage: [UInt](repeating: .max, count: 9))
        XCTAssertEqual(moreEnough, -1)
    }

    func testSign() {
        XCTAssertTrue(i200(-123657).isNegative)
    }

    func testComparable() {
        XCTAssertLessThan(i200(0), i200(1))
        XCTAssertLessThan(i200(-1), i200(0))
        XCTAssertLessThan(i200(-2), i200(-1))
        XCTAssertLessThan(i200(-2), i200(1))
        XCTAssertGreaterThan(i200(2), i200(-1))
        XCTAssertLessThan(i200(1), i200(2))
    }

    func testInvert() {
        let z: i200 = 1
        let minusZ: i200 = -2
        XCTAssertEqual(~z, minusZ)
    }

    func testAdd() {
        XCTAssertEqual(i200(0) + 0, 0)
        XCTAssertEqual(i200(0) + 1, 1)
        XCTAssertEqual(i200(1) + 0, 1)
        XCTAssertEqual(i200(1) + 1, 2)
        XCTAssertEqual(i200("803469022129495137770981046170581301261101496891396417650687") + 0, i200("803469022129495137770981046170581301261101496891396417650687"))
        XCTAssertEqual(i200(-30) + i200(-1), -31)
        XCTAssertEqual(i200("-1606938044258990275541962092341162602522202993782792835301375") + i200(-1), i200("1606938044258990275541962092341162602522202993782792835301376"))
    }

    func testIsPositive() {
        XCTAssertTrue(i200(1).isPositive)
        XCTAssertFalse(i200(0).isPositive)
        XCTAssertFalse(i200(-1).isPositive)
    }

    func testSubtract() {
        XCTAssertEqual(i200(3) - 2, 1)
        XCTAssertEqual(i200(7) - 4, 3)
    }

    func testAddOverflow() {
        assert(i200("803469022129495137770981046170581301261101496891396417650687"), i200.addingReportingOverflow(_:), 1, (i200("-803469022129495137770981046170581301261101496891396417650688"), true))
        assert(i200("-803469022129495137770981046170581301261101496891396417650688"), i200.addingReportingOverflow(_:), -1, (i200("803469022129495137770981046170581301261101496891396417650687"), true))

        assert(i200("-803469022129495137770981046170581301261101496891396417650687"), i200.addingReportingOverflow(_:), -1, ("-803469022129495137770981046170581301261101496891396417650688", false))
    }

    func testSubtractOverflow() {
        assert(i200("-803469022129495137770981046170581301261101496891396417650688"), i200.subtractingReportingOverflow(_:), 1, (i200("803469022129495137770981046170581301261101496891396417650687"), true))
        assert(i200("803469022129495137770981046170581301261101496891396417650687"), i200.subtractingReportingOverflow(_:), -1, (i200("-803469022129495137770981046170581301261101496891396417650688"), true))
    }

    func testMultiplyOverflow() {
        assert(i200("401734511064747568885490523085290650630550748445698208825344"), i200.multipliedReportingOverflow(by:), 2, (i200("-803469022129495137770981046170581301261101496891396417650688"), true))
        assert(i200("-401734511064747568885490523085290650630550748445698208825345"), i200.multipliedReportingOverflow(by:), 2, (i200("803469022129495137770981046170581301261101496891396417650686"), true))
    }

    func testDivideFullWidth() {
        let dividend = (i200(-1), i200(0).magnitude)
        let divisor = i200(2)
        let (q, r) = divisor.dividingFullWidth(dividend)
        XCTAssertEqual(q, i200("-803469022129495137770981046170581301261101496891396417650688"))
        XCTAssertEqual(r, i200(0))
    }

    func testBitCounts() {
        XCTAssertEqual(i200(0).nonzeroBitCount, 0)
        XCTAssertEqual(i200(1).nonzeroBitCount, 1)
        XCTAssertEqual(i200("803469022129495137770981046170581301261101496891396417650687").nonzeroBitCount, 199)
        XCTAssertEqual(i200(-1).nonzeroBitCount, 200)

        XCTAssertEqual(i200(0).leadingZeroBitCount, 200)
        XCTAssertEqual(i200(1).leadingZeroBitCount, 199)
        XCTAssertEqual(i200(31).leadingZeroBitCount, 195)
        XCTAssertEqual(i200("803469022129495137770981046170581301261101496891396417650687").leadingZeroBitCount, 1)
        XCTAssertEqual(i200(-1).leadingZeroBitCount, 0)

        XCTAssertEqual(i200(0).trailingZeroBitCount, 200)
        XCTAssertEqual(i200(1).trailingZeroBitCount, 0)
        XCTAssertEqual(i200(2).trailingZeroBitCount, 1)
        XCTAssertEqual(i200("-803469022129495137770981046170581301261101496891396417650688").trailingZeroBitCount, 199)
    }

    func testByteSwap() {
        XCTAssertEqual(i200(1).byteSwapped, i200("6277101735386680763835789423207666416102355444464034512896"))
    }

    func test200Negative() {
        let a = i200(-1)
        let expected: [UInt] = [0xff, 0xff_ff_ff_ff_ff_ff_ff_ff, 0xff_ff_ff_ff_ff_ff_ff_ff, 0xff_ff_ff_ff_ff_ff_ff_ff].reversed()
        XCTAssertEqual(a.words, expected)
    }

    func testRightShift() {
        let a = i200(-3)
        XCTAssertEqual(a >> 1, i200(-2))
    }

    func testExactlyBig() {
        // max = 2^(n-1) - 1 = 2^199 - 1 = 803469022129495137770981046170581301261101496891396417650687
        // 2^199 must crash = 803469022129495137770981046170581301261101496891396417650688
        XCTAssertNil(i200(exactlyBig: "803469022129495137770981046170581301261101496891396417650688"))
        XCTAssertNotNil(i200(exactlyBig: "803469022129495137770981046170581301261101496891396417650687"))
        XCTAssertNotNil(i200(exactlyBig: "-803469022129495137770981046170581301261101496891396417650688"))
        XCTAssertEqual(i200(exactlyBig: "-1"), -1)
    }

    func testInitExactlyFromSource() {
        let max = TestUInt200.max
        XCTAssertNil(i200(exactly: max))
        XCTAssertNotNil(i200(exactly: 5))
    }

    func testAlgo() {
        XCTAssertEqual(log2(i200(1024)), 10)
        XCTAssertEqual(log2(i200(1_048_576)), 20)
        XCTAssertEqual(pow(i200(10), 1), 10)
        XCTAssertEqual(pow(i200(10), 0), 1)
        XCTAssertEqual(pow(i200(10), 25), i200("10000000000000000000000000"))
        XCTAssertEqual(log10(i200("10000000000000000000000000")), 25)
        XCTAssertEqual(log10(i200("10000000000000000000000000")), 25)
        XCTAssertEqual(log10(i200("803469022129495137770981046170581301261101496891396417650687")), 59)
        XCTAssertEqual(log2(i200("803469022129495137770981046170581301261101496891396417650687")), 198)
    }

    func assert(_ a: i200, _ op: (i200, i200) -> i200, _ b: i200, _ c: i200, line: UInt = #line) {
        XCTAssertEqual(op(a, b), c, line: line)
    }

    func assert(_ a: i200, _ op: (i200) -> (i200) -> (i200, Bool), _ b: i200, _ c: (i200, Bool), line: UInt = #line) {
        let result = op(a)(b)
        XCTAssertEqual(result.0, c.0, line: line)
        XCTAssertEqual(result.1, c.1, line: line)
    }
}
