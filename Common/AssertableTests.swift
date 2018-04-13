//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class AssertableTests: XCTestCase {

    class A: Assertable {}
    enum E: Error, Hashable { case error }

    func test_whenAssertionFails_throwsError() {
        XCTAssertThrowsError(try A.assertArgument(false, E.error)) {
            XCTAssertEqual($0 as? E, .error)
        }
    }

    func test_whenAssertionPasses_doesNotThrow() {
        XCTAssertNoThrow(try A.assertArgument(true, E.error))
    }

}
