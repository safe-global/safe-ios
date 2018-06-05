//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// `Logger` provides means to log different types of messages and accompany them with optional Error objects.
public protocol Logger {

    /// Indicates a fatal error occurred. The application is supposed to be terminated soon.
    ///
    /// - Parameters:
    ///   - message: Fatal error message
    ///   - error: optional error that caused the fatal situation
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func fatal(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    /// Indicates that an error occurred. The application is supposed to still work.
    ///
    /// - Parameters:
    ///   - message: Error message
    ///   - error: optional error that caused the error situation
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func error(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    /// Indicates some important information.
    ///
    /// - Parameters:
    ///   - message: Info message
    ///   - error: optional error
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
    func info(_ message: String, error: Error?, file: StaticString, line: UInt, function: StaticString)
    /// Indicates a debug message.
    ///
    /// - Parameters:
    ///   - message: Debug message
    ///   - error: optional error
    ///   - file: file from where this method was invoked
    ///   - line: line in `file` from where this method was invoked
    ///   - function: name of the method from where this method was invoked
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
