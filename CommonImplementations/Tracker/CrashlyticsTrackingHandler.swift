//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common
import Crashlytics

/// Logs tracking events to record them for crashes.
public final class CrashlyticsTrackingHandler: TrackingHandler {

    public init() {}

    public func track(event: String, parameters: [String: Any]?) {
        let parametersString = parameters != nil ? (", parameters: " + String(describing: parameters!)) : ""
        CLSLogv("[TRACKING] event: '%@'%@", getVaList([event, parametersString]))
    }

}
