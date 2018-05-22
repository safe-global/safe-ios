//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Logger {

    func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    func debug(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)

}

public extension Logger {

    func fatal(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.fatal(message, error: error, file: file, line: line, function: function)
    }

    func error(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.error(message, error: error, file: file, line: line, function: function)
    }

    func info(_ message: String,
              error: Error? = nil,
              file: StaticString = #file,
              line: UInt = #line,
              function: StaticString = #function) {
        self.info(message, error: error, file: file, line: line, function: function)
    }

    func debug(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               line: UInt = #line,
               function: StaticString = #function) {
        self.debug(message, error: error, file: file, line: line, function: function)
    }

}
