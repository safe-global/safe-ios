//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Logs all events to the console log.
final class ConsoleTracker: TrackingHandler {

    /// You will find the events by the "[TRACKING]" tag in the log.
    func track(event: String, parameters: [String: Any]?) {
        let parametersString = parameters != nil ? (", parameters: " + String(describing: parameters!)) : ""
        LogService.shared.info("[TRACKING] event: '\(event)'" + parametersString)
    }

}
