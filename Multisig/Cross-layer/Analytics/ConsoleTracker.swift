//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Logs all events to the console log.
final class ConsoleTracker: TrackingHandler {
    private var trackingEnabled = true

    /// You will find the events by the "[TRACKING]" tag in the log.
    func track(event: String, parameters: [String: Any]?) {
        guard trackingEnabled else { return }
        let parametersString = parameters != nil ? (", parameters: " + String(describing: parameters!)) : ""
        LogService.shared.info("[TRACKING] event: '\(event)'" + parametersString)
    }

    func setUserProperty(_ value: String, for property: UserProperty) {
        guard trackingEnabled else { return }
        LogService.shared.info("[TRACKING] setUserProperty: '\(value)' for \(property.rawValue)")
    }

    func setTrackingEnabled(_ value: Bool) {
        trackingEnabled = value
    }
}
