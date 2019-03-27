//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class LoggableErrorTests: XCTestCase {

    func test_loggableError() {
        let nsError = TestLoggableError.error.nsError()
        XCTAssertEqual(nsError.domain, String(describing: TestLoggableError.self))
        XCTAssertEqual(nsError.code, 0)
        XCTAssertEqual(nsError.userInfo[NSLocalizedDescriptionKey] as? String,
                       TestLoggableError.error.localizedDescription)
        XCTAssertEqual(nsError.userInfo[LoggableErrorDescriptionKey] as? String, "\(TestLoggableError.error)")
    }

    func test_loggableErrorPreservesReason() {
        let nsError = TestLoggableError.error.nsError(causedBy: TestLoggableError.error)
        XCTAssertTrue(nsError.userInfo[NSUnderlyingErrorKey] is NSError)
        XCTAssertEqual((nsError.userInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription,
                       TestLoggableError.error.localizedDescription)
    }

}
