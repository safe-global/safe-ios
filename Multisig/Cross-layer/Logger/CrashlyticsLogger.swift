//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Firebase

/// Protocol for enabling logger tests
public protocol CrashlyticsProtocol {
    func record(error: Error)
    func log(format: String, arguments: CVaListPointer)
    func setCrashlyticsCollectionEnabled(_ enabled: Bool)
}

/// Implements Crashlytics error logging. Logs are send to Crashlytics if log message contains non-nil `error` argument.
final class CrashlyticsLogger: LogWriter {

    private let crashlytics: CrashlyticsProtocol

    /// Creates logger.
    ///
    /// - Parameter crashlytics: default value is the Crashlytics shared instance.
    init(crashlytics: CrashlyticsProtocol = Crashlytics.crashlytics()) {
        self.crashlytics = crashlytics
        self.crashlytics.setCrashlyticsCollectionEnabled(AppSettings.trackingEnabled)
    }

    func log(_ message: String,
             level: LogLevel,
             error: Error?,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        guard let error = error else {
            crashlytics.log(
                format: "[%@] %@:%@:%@: %@",
                arguments: getVaList([level.string, file.description, String(line), function.description, message]))
            return
        }
        let nsError: NSError
        if let loggable = error as? LoggableError {
            nsError = loggable.nsError()
        } else {
            nsError = error as NSError
        }
        var userInfo = nsError.userInfo
        userInfo["message"] = message
        let recordedError = NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
        crashlytics.record(error: recordedError)
    }

}

extension Crashlytics: CrashlyticsProtocol {}
