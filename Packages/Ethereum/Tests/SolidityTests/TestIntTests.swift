//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 25.12.21.
//

import Foundation
import XCTest
import Solidity

class TestIntTests: XCTestCase {
    typealias u200 = TestInt200

    func testInit() {
        let empty = u200(storage: [])
        XCTAssertEqual(empty, 0)

        let notEnough = u200(storage: [UInt](repeating: .max, count: 1))
        XCTAssertEqual(notEnough, -1)

        let enough = u200(storage: [UInt](repeating: .max, count: 200 / UInt.bitWidth + 1))
        XCTAssertEqual(enough, -1)

        let moreEnough = u200(storage: [UInt](repeating: .max, count: 9))
        XCTAssertEqual(moreEnough, -1)
    }

    func testSign() {
        XCTAssertTrue(u200(-123657).isNegative)
    }

    func testComparable() {
        XCTAssertLessThan(u200(0), u200(1))
        XCTAssertLessThan(u200(-1), u200(0))
        XCTAssertLessThan(u200(-2), u200(-1))
        XCTAssertLessThan(u200(-2), u200(1))
        XCTAssertGreaterThan(u200(2), u200(-1))
        XCTAssertLessThan(u200(1), u200(2))
    }

    func testInvert() {
        let z: u200 = 1
        let minusZ: u200 = -2
        XCTAssertEqual(~z, minusZ)
    }

    func testAdd() {
        XCTAssertEqual(u200(0) + 0, 0)
        XCTAssertEqual(u200(0) + 1, 1)
        XCTAssertEqual(u200(1) + 0, 1)
        XCTAssertEqual(u200(1) + 1, 2)
        XCTAssertEqual(u200("803469022129495137770981046170581301261101496891396417650687") + 0, u200("803469022129495137770981046170581301261101496891396417650687"))
        XCTAssertEqual(u200(-30) + u200(-1), -31)
        XCTAssertEqual(u200("-1606938044258990275541962092341162602522202993782792835301375") + u200(-1), u200("1606938044258990275541962092341162602522202993782792835301376"))
    }

    func testIsPositive() {
        XCTAssertTrue(u200(1).isPositive)
        XCTAssertFalse(u200(0).isPositive)
        XCTAssertFalse(u200(-1).isPositive)
    }

    func testSubtract() {
        XCTAssertEqual(u200(3) - 2, 1)
        XCTAssertEqual(u200(7) - 4, 3)
    }

    func testAddOverflow() {
        assert(u200("803469022129495137770981046170581301261101496891396417650687"), u200.addingReportingOverflow(_:), 1, (u200("-803469022129495137770981046170581301261101496891396417650688"), true))
        assert(u200("-803469022129495137770981046170581301261101496891396417650688"), u200.addingReportingOverflow(_:), -1, (u200("803469022129495137770981046170581301261101496891396417650687"), true))

        assert(u200("-803469022129495137770981046170581301261101496891396417650687"), u200.addingReportingOverflow(_:), -1, ("-803469022129495137770981046170581301261101496891396417650688", false))
    }

    func testSubtractOverflow() {
        assert(u200("-803469022129495137770981046170581301261101496891396417650688"), u200.subtractingReportingOverflow(_:), 1, (u200("803469022129495137770981046170581301261101496891396417650687"), true))
        assert(u200("803469022129495137770981046170581301261101496891396417650687"), u200.subtractingReportingOverflow(_:), -1, (u200("-803469022129495137770981046170581301261101496891396417650688"), true))
    }

    func testMultiplyOverflow() {
        assert(u200("401734511064747568885490523085290650630550748445698208825344"), u200.multipliedReportingOverflow(by:), 2, (u200("-803469022129495137770981046170581301261101496891396417650688"), true))
        assert(u200("-401734511064747568885490523085290650630550748445698208825345"), u200.multipliedReportingOverflow(by:), 2, (u200("803469022129495137770981046170581301261101496891396417650686"), true))
    }

    func testDivideFullWidth() {
        let dividend = (u200(-1), u200(0).magnitude)
        let divisor = u200(2)
        let (q, r) = divisor.dividingFullWidth(dividend)
        XCTAssertEqual(q, u200("-803469022129495137770981046170581301261101496891396417650688"))
        XCTAssertEqual(r, u200(0))
    }

    func testBitCounts() {
        XCTAssertEqual(u200(0).nonzeroBitCount, 0)
        XCTAssertEqual(u200(1).nonzeroBitCount, 1)
        XCTAssertEqual(u200("803469022129495137770981046170581301261101496891396417650687").nonzeroBitCount, 199)
        XCTAssertEqual(u200(-1).nonzeroBitCount, 200)

        XCTAssertEqual(u200(0).leadingZeroBitCount, 200)
        XCTAssertEqual(u200(1).leadingZeroBitCount, 199)
        XCTAssertEqual(u200(31).leadingZeroBitCount, 195)
        XCTAssertEqual(u200("803469022129495137770981046170581301261101496891396417650687").leadingZeroBitCount, 1)
        XCTAssertEqual(u200(-1).leadingZeroBitCount, 0)

        XCTAssertEqual(u200(0).trailingZeroBitCount, 200)
        XCTAssertEqual(u200(1).trailingZeroBitCount, 0)
        XCTAssertEqual(u200(2).trailingZeroBitCount, 1)
        XCTAssertEqual(u200("-803469022129495137770981046170581301261101496891396417650688").trailingZeroBitCount, 199)
    }

    func testByteSwap() {
        XCTAssertEqual(u200(1).byteSwapped, u200("6277101735386680763835789423207666416102355444464034512896"))
    }

    func assert(_ a: u200, _ op: (u200, u200) -> u200, _ b: u200, _ c: u200, line: UInt = #line) {
        XCTAssertEqual(op(a, b), c, line: line)
    }

    func assert(_ a: u200, _ op: (u200) -> (u200) -> (u200, Bool), _ b: u200, _ c: (u200, Bool), line: UInt = #line) {
        let result = op(a)(b)
        XCTAssertEqual(result.0, c.0, line: line)
        XCTAssertEqual(result.1, c.1, line: line)
    }
}
