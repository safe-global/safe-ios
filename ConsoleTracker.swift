//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// Logs all events to the console log.
public final class ConsoleTracker: TrackingHandler {

    public init() {}

    /// You will find the events by the "[TRACKING]" tag in the log.
    public func track(event: String, parameters: [String: Any]?) {
        let parametersString = parameters != nil ? (", parameters: " + String(describing: parameters!)) : ""
        LogService.shared.info("[TRACKING] event: '\(event)'" + parametersString)
    }

}
