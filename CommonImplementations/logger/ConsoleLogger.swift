//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

final class ConsoleLogger: LogWriter {

    private let formatter = LogFormatter()

    func log(_ message: String,
             level: LogLevel,
             error: Error?,
             file: StaticString,
             line: UInt,
             function: StaticString) {
        let str = formatter.string(from: message,
                                   logLevel: level,
                                   error: error,
                                   filename: String(describing: file),
                                   method: String(describing: function),
                                   line: line,
                                   timestamp: Date())
        print(str)
    }

}
