//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class FoundationExtensionsTests: XCTestCase {

    let empty = ""
    let noDigit = "a"
    let oneDigit = "1"
    let oneLowercase = "a"
    let oneUppercase = "A"
    let manyContainsNoneUppercase = "abc"
    let manyContainsOneDigit = "ab1"
    let manyContainsNoneDigit = "abc"
    let manyContainsManyDigits = "a12"
    let double = "aa"
    let tripple = "aaa"
    let trippleInTheMiddle = "1aaa4"
    let trippleInTheEnd = "1aa4bbb"

    func test_hasLetter() {
        XCTAssertFalse(empty.hasLetter)
        XCTAssertFalse(oneDigit.hasLetter)
        XCTAssertTrue(oneLowercase.hasLetter)
        XCTAssertTrue(oneUppercase.hasLetter)
        XCTAssertTrue(manyContainsNoneUppercase.hasLetter)
    }

    func test_hasDecimalDigit() {
        XCTAssertFalse(empty.hasDecimalDigit)
        XCTAssertFalse(noDigit.hasDecimalDigit)
        XCTAssertTrue(oneDigit.hasDecimalDigit)
        XCTAssertTrue(manyContainsOneDigit.hasDecimalDigit)
        XCTAssertFalse(manyContainsNoneDigit.hasDecimalDigit)
        XCTAssertTrue(manyContainsManyDigits.hasDecimalDigit)
    }

    func test_hasNoTrippleChar() {
        XCTAssertTrue(empty.hasNoTrippleChar)
        XCTAssertTrue(oneDigit.hasNoTrippleChar)
        XCTAssertTrue(double.hasNoTrippleChar)
        XCTAssertFalse(tripple.hasNoTrippleChar)
        XCTAssertFalse(trippleInTheMiddle.hasNoTrippleChar)
        XCTAssertFalse(trippleInTheEnd.hasNoTrippleChar)
    }

}
