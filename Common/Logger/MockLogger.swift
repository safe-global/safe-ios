//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// `MockLogger` implements `Logger` protocol for use in unit tests.
public class MockLogger: Logger {

    public var fatalLogged = false
    public var errorLogged = false
    public var infoLogged = false
    public var debugLogged = false

    public var loggedError: Error?

    public init() {}

    public func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        fatalLogged = true
        loggedError = error
    }

    public func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        errorLogged = true
        loggedError = error
    }

    public func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        infoLogged = true
        loggedError = error
    }

    public func debug(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, Date(), message, error == nil ? "" : error!)
        debugLogged = true
        loggedError = error
    }

}
