//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import Common

public final class FirebaseTrackingHandler: TrackingHandler {

    public init() {}

    public func track(view: TrackingView, contentId: String?, parameters: [String: Any]?) {
//        Analytics.logEvent(AnalyticsEventSelectContent, parameters: parameters)
        Analytics.logEvent(view.rawValue, parameters: parameters)
    }

    public func track(event: TrackingEvent, view: TrackingView?, parameters: [String: Any]?) {}

}
