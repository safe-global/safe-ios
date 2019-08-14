//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import CommonImplementations
import Common
import CommonTestSupport

class LogFormatterTests: XCTestCase {

    let formatter = LogFormatter()
    let testMsg = "*** %l - Log Level %f - Filename %n - Line in file %m - Method name %s - Message %t - Timestamp ***"

    override func setUp() {
        super.setUp()
    }

    func test_defaultFormat() {
        XCTAssertEqual(formatter.dateFormat, LogFormatter.defaultDateFormat)
        XCTAssertEqual(formatter.format, LogFormatter.defaultMessageFormat)
    }

    func test_messageParameter() {
        formatter.format = "Test %s parameter."
        XCTAssertEqual(formatter.string(from: testMsg), "Test \(testMsg) parameter.")
    }

    func test_logLevelFormat() {
        formatter.format = "Test %l parameter."
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .off), "Test OFF parameter.")
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .fatal), "Test FATAL parameter.")
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .error), "Test ERROR parameter.")
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .info), "Test INFO parameter.")
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .debug), "Test DEBUG parameter.")
    }

    func test_errorFormat() {
        formatter.format = "Test %e parameter."
        XCTAssertEqual(formatter.string(from: testMsg, error: TestError.error), "Test (error) parameter.")
        XCTAssertEqual(formatter.string(from: testMsg, error: nil), "Test  parameter.")
    }

    func test_filenameFormat() {
        formatter.format = "Test %f parameter."
        XCTAssertEqual(formatter.string(from: testMsg, filename: "test.swift"), "Test test.swift parameter.")
    }

    func test_filename_whenFullPathSpecified_takesFilenameOnly() {
        formatter.format = "Test %f parameter."
        XCTAssertEqual(formatter.string(from: testMsg, filename: "/home/test/test.swift"), "Test test.swift parameter.")
    }

    func test_lineFormat() {
        formatter.format = "Test %n parameter."
        XCTAssertEqual(formatter.string(from: testMsg, line: 50), "Test 50 parameter.")
    }

    func test_methodFormat() {
        formatter.format = "Test %m parameter."
        XCTAssertEqual(formatter.string(from: testMsg, method: "test()"), "Test test() parameter.")
    }

    func test_timestampFormat() {
        formatter.format = "Test %t parameter."
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter.dateFormat
        XCTAssertEqual(formatter.string(from: testMsg, timestamp: date),
                       "Test \(dateFormatter.string(from: date)) parameter.")
    }

    func test_allTogetherParameters() {
        formatter.format = "Test %l %f %n %m %s %t parameters."
        XCTAssertEqual(formatter.string(from: testMsg, logLevel: .off),
                       "Test \(LogLevel.off.string) %f %n %m \(testMsg) %t parameters.")
    }

}
