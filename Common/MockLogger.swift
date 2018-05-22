//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class MockLogger: Logger {

    public var fatalLogged = false
    public var errorLogged = false
    public var infoLogged = false
    public var debugLogged = false

    public init() {}

    public func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, message, error == nil ? "" : error!)
        fatalLogged = true
    }

    public func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        print(file, function, line, message, error == nil ? "" : error!)
        errorLogged = true
    }

    public func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        infoLogged = true
        print(file, function, line, message, error == nil ? "" : error!)
    }

    public func debug(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString) {
        debugLogged = true
        print(file, function, line, message, error == nil ? "" : error!)
    }

}
