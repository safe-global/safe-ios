//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/**
 %l - Log Level
 %f - Filename
 %n - Line in file
 %m - Method name
 %s - Message
 %t - Timestamp
 %e - Error
 */
final class LogFormatter {

    static let defaultDateFormat = "yyyy-MM-dd hh:mm:ss.SSSSSS"
    static let defaultMessageFormat = "%t [%l] %f:%n %m: %s %e"

    private let dateFormatter = DateFormatter()
    var dateFormat = defaultDateFormat
    var format = defaultMessageFormat

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
