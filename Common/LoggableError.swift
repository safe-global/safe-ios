//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public let LoggableErrorDescriptionKey = "LoggableErrorDescriptionKey"

public protocol LoggableError: Error {
    func nsError(causedBy: Error?) -> NSError
}

public extension LoggableError {

    func nsError(causedBy underlyingError: Error? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: localizedDescription,
                                       LoggableErrorDescriptionKey: String(describing: self)]
        if let error = underlyingError {
            userInfo[NSUnderlyingErrorKey] = error as NSError
        }
        return NSError(domain: String(describing: type(of: self)),
                       code: (self as NSError).code,
                       userInfo: userInfo)
    }

}

public enum TestLoggableError: LoggableError {
    case error
}
