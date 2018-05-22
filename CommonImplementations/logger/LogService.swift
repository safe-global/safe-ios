//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

protocol LogWriter {

    func log(_ message: String, level: LogLevel, error: Error?, file: StaticString, line: UInt, function: StaticString)

}

extension LogWriter {

    func log(_ message: String,
             level: LogLevel,
             error: Error? = nil,
             file: StaticString = #file,
             line: UInt = #line,
             function: StaticString = #function) {
        self.log(message, level: level, error: error, file: file, line: line, function: function)
    }

}

/**
 FATAL: Designates very severe error events that will presumably lead the application to abort.
 
 ERROR: Designates error events that might still allow the application to continue running.
 
 INFO: Designates informational messages that highlight the progress of the application at coarse-grained level.
 
 DEBUG: Designates fine-grained informational events that are most useful to debug an application.
 */
public enum LogLevel: Int {
    case off
    case fatal
    case error
    case info
    case debug

    var string: String {
        switch self {
        case .off: return "OFF"
        case .fatal: return "FATAL"
        case .error: return "ERROR"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        }
    }

    private static let values: [String: LogLevel] = {
        var result = [String: LogLevel]()
        let all: [LogLevel] = [.off, .fatal, .error, .info, .debug]
        all.forEach { result[$0.string] = $0 }
        return result
    }()

    init(string: String) {
        self = LogLevel.values[string.uppercased()]  ?? .off
    }

}

/// Must be a string value. Valid values: LogLevel names
public let LogServiceLogLevelKey = "SafeLogServiceLogLevelKey"
/// Must be comma-separated string of loggers. Valid loggers: crashlytics, console - case-insensitive
public let LogServiceEnabledLoggersKey = "SafeLogServiceEnabledLoggersKey"
let LogServiceConsoleLoggerIdentifier = "console"
let LogServiceCrashlyticsLoggerIdentifier = "crashlytics"

protocol BundleProtocol {

    func object(forInfoDictionaryKey key: String) -> Any?

}

extension Bundle: BundleProtocol {}

public final class LogService: Logger {

    public static let shared = LogService()

    public let level: LogLevel
    private (set) var loggers = [LogWriter]()

    init(level: LogLevel) {
        self.level = level
    }

    init(bundle: BundleProtocol = Bundle.main) {
        let string = bundle.object(forInfoDictionaryKey: LogServiceLogLevelKey) as? String ?? ""
        level = LogLevel(string: string)
        addLoggers(from: bundle)
    }

    private func addLoggers(from bundle: BundleProtocol) {
        guard let enabledLoggers = bundle.object(forInfoDictionaryKey: LogServiceEnabledLoggersKey) as? String else {
            return
        }
        let normalizedEnabledLoggers = enabledLoggers.split(separator: ",").map {
            $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if normalizedEnabledLoggers.contains(LogServiceConsoleLoggerIdentifier) {
            add(ConsoleLogger())
        }
        if normalizedEnabledLoggers.contains(LogServiceCrashlyticsLoggerIdentifier) {
            add(CrashlyticsLogger())
        }
    }

    public func fatal(_ message: String,
                      error: Error? = nil,
                      file: StaticString = #file,
                      line: UInt = #line,
                      function: StaticString = #function) {
        log(.fatal, message: message, error: error, file: file, line: line, function: function)
    }

    public func error(_ message: String,
                      error: Error? = nil,
                      file: StaticString = #file,
                      line: UInt = #line,
                      function: StaticString = #function) {
        log(.error, message: message, error: error, file: file, line: line, function: function)
    }

    public func info(_ message: String,
                     error: Error? = nil,
                     file: StaticString = #file,
                     line: UInt = #line,
                     function: StaticString = #function) {
        log(.info, message: message, error: error, file: file, line: line, function: function)
    }

    public func debug(_ message: String,
                      error: Error? = nil,
                      file: StaticString = #file,
                      line: UInt = #line,
                      function: StaticString = #function) {
        log(.debug, message: message, error: error, file: file, line: line, function: function)
    }

    private func log(_ level: LogLevel,
                     message: String,
                     error: Error?,
                     file: StaticString,
                     line: UInt,
                     function: StaticString) {
        guard self.level.rawValue >= level.rawValue else { return }
        loggers.forEach { $0.log(message, level: level, error: error, file: file, line: line, function: function) }
    }

    func add(_ logger: LogWriter) {
        loggers.append(logger)
    }

    func add(_ loggers: [LogWriter]) {
        self.loggers.append(contentsOf: loggers)
    }

}
