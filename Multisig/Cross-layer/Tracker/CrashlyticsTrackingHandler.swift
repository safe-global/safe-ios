//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
//import Crashlytics

/// Logs tracking events to record them for crashes.
final class CrashlyticsTrackingHandler: TrackingHandler {

    func track(event: String, parameters: [String: Any]?) {
        let parametersString = parameters != nil ? (", parameters: " + String(describing: parameters!)) : ""
        #warning("TODO: enable when Crashlytics is integrated")
//        CLSLogv("[TRACKING] event: '%@'%@", getVaList([event, parametersString]))
    }

}
