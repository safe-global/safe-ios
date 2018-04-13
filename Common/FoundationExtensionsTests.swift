//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class FoundationExtensionsTests: XCTestCase {

    func test_containsCapitalizedLetter() {
        let empty = ""
        let oneLowercase = "a"
        let oneUppercase = "A"
        let manyContainsOneUppercase = "abC"
        let manyContainsNoneUppercase = "abc"
        let manyContainsManyUppercase = "aBC"
        XCTAssertFalse(empty.hasUppercaseLetter)
        XCTAssertFalse(oneLowercase.hasUppercaseLetter)
        XCTAssertTrue(oneUppercase.hasUppercaseLetter)
        XCTAssertTrue(manyContainsOneUppercase.hasUppercaseLetter)
        XCTAssertFalse(manyContainsNoneUppercase.hasUppercaseLetter)
        XCTAssertTrue(manyContainsManyUppercase.hasUppercaseLetter)
    }

    func test_containsDigit() {
        let empty = ""
        let noDigit = "a"
        let oneDigit = "1"
        let manyContainsOneDigit = "ab1"
        let manyContainsNoneDigit = "abc"
        let manyContainsManyDigits = "a12"
        XCTAssertFalse(empty.hasDecimalDigit)
        XCTAssertFalse(noDigit.hasDecimalDigit)
        XCTAssertTrue(oneDigit.hasDecimalDigit)
        XCTAssertTrue(manyContainsOneDigit.hasDecimalDigit)
        XCTAssertFalse(manyContainsNoneDigit.hasDecimalDigit)
        XCTAssertTrue(manyContainsManyDigits.hasDecimalDigit)
    }

}
