//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Crashlytics
import Common

protocol CrashlyticsProtocol {
    func recordError(_ error: Error)
}

final class CrashlyticsLogger: LogWriter {

    private let crashlytics: CrashlyticsProtocol

    init(crashlytics: CrashlyticsProtocol = Crashlytics.sharedInstance()) {
        self.crashlytics = crashlytics
    }

    func log(_ message: String,
             level: LogLevel,
             error: Error?,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        guard let error = error else { return }
        let nsError: NSError
        if let loggable = error as? LoggableError {
            nsError = loggable.nsError()
        } else {
            nsError = error as NSError
        }
        var userInfo = nsError.userInfo
        userInfo["message"] = message
        crashlytics.recordError(NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo))
    }

}

extension Crashlytics: CrashlyticsProtocol {}
