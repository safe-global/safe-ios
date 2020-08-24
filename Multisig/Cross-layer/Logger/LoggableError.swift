//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public let LoggableErrorDescriptionKey = "LoggableErrorDescriptionKey"

/// Default implementation of utility to convert any `Swift.Error` to `NSError`
public protocol LoggableError: Error {

    /// Creates `NSError` and puts the `causedBy` error into `NSError.userInfo` dictionary.
    ///
    /// - Parameter causedBy: Underlying error
    /// - Returns: new NSError with `causedBy` underlying error inside.
    func nsError(causedBy: Error?) -> NSError

    var domain: String { get }
    var code: Int { get }
}

public extension LoggableError {

    var domain: String { "LoggableError" }
    var code: Int { 0 }

    func nsError(causedBy underlyingError: Error? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: localizedDescription,
                                       LoggableErrorDescriptionKey: String(describing: self)]
        if let error = underlyingError {
            userInfo[NSUnderlyingErrorKey] = error as NSError
        }
        return NSError(domain: domain,
                       code: code,
                       userInfo: userInfo)
    }

}

/// Loggable error that can be used in tests.
public enum TestLoggableError: LoggableError {
    /// Test error
    case error

    public var domain: String { "TestLoggableError" }
    public var code: Int { 1 }
}
