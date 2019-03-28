//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/**
 `LogFormatter` specifies special substitution characters that are used to define format of a single log message.
 */
final class LogFormatter {

    /// The default date format used for the timestamp is "yyyy-MM-dd hh:mm:ss.SSSSSS"
    static let defaultDateFormat = "yyyy-MM-dd hh:mm:ss.SSSSSS"
    /// The default message format
    static let defaultMessageFormat = "%t [%l] %f:%n %m: %s %e"

    private let dateFormatter = DateFormatter()
    /// Format to use for timestamps
    var dateFormat = defaultDateFormat

    /** Format to use for log messages.

    The available characters are:
    - %l - Log Level
    - %f - Filename
    - %n - Line in file
    - %m - Method name
    - %s - Message
    - %t - Timestamp
    - %e - Error
     */
    var format = defaultMessageFormat

    /// Returns formatted log message based on the parameters and current values of `format` and `dateFormat`.
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - logLevel: Log level.
    ///   - error: Error
    ///   - filename: File name where the log occurred
    ///   - method: Method name where the log occurred
    ///   - line: Line in the `filename` where the log occurred
    ///   - timestamp: Time when the log occurred
    /// - Returns: String, formatted according to the `format`.
    func string(from message: String,
                logLevel: LogLevel? = nil,
                error: Error? = nil,
                filename: String? = nil,
                method: String? = nil,
                line: UInt? = nil,
                timestamp: Date? = nil) -> String {
        var result = format
        if let logLevel = logLevel {
            result = result.replacingOccurrences(of: "%l", with: logLevel.string)
        }
        let errorStr = error != nil ? "(\(error!))" : ""
        result = result.replacingOccurrences(of: "%e", with: errorStr)
        if let filename = filename {
            result = result.replacingOccurrences(of: "%f", with: URL(fileURLWithPath: "\(filename)").lastPathComponent)
        }
        if let method = method {
            result = result.replacingOccurrences(of: "%m", with: method)
        }
        if let line = line {
            result = result.replacingOccurrences(of: "%n", with: String(describing: line))
        }
        if let timestamp = timestamp {
            result = result.replacingOccurrences(of: "%t", with: dateString(timestamp))
        }
        return result.replacingOccurrences(of: "%s", with: message)
    }

    private func dateString(_ date: Date) -> String {
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }

}
