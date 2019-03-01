//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol TrackingHandler {
    func track(event: Trackable, parameters: [String: Any]?)
}

public protocol Trackable {
    var rawValue: String { get }
}

public class Tracker {

    public static let shared = Tracker()

    private var trackingHandlers = [TrackingHandler]()

    public func append(handler: TrackingHandler) {
        trackingHandlers.append(handler)
    }

    public func track(event: Trackable, parameters: [String: Any]? = nil) {
        for handler in trackingHandlers {
            handler.track(event: event, parameters: parameters)
        }
    }

}
