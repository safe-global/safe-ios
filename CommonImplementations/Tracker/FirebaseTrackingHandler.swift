//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import Common

public final class FirebaseTrackingHandler: TrackingHandler {

    public init() {}

    public func track(event: Trackable, parameters: [String: Any]?) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

}
