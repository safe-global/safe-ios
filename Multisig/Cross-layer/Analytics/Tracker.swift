//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

/**
 This class is a singleton used throughout the app to track events.

 To track an event, create an enum that conforms to Trackable or ScreenTrackingEvent protocol. For example:

     enum MyScreenEvent: String, ScreenTrackingEvent {
        case eventName = "ScreenId_EventName"
     }

     enum MyCustomEvent: String, Trackable {
        case myEvent = "MyCustomEventName"

         var name: String { return rawValue }
         var parameters: [String: Any]? { return ["my_parameter": "my_value"] }

     }

 Then, from a view controller's `viewDidAppear` method call `trackEvent` method on UIViewController:

     override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         trackEvent(MyMenuEvent.eventName)
     }

 Finally, you can subclass the Tracker for testing purposes. In that case, replace the singleton instance stored in
 the `shared` property.

 */
class Tracker {
    /// Singleton instance.
    static var shared = Tracker()

    /// All registered objects handling tracking events
    private var trackingHandlers = [TrackingHandler]()

    /// Registers new handler of tracking events.
    ///
    /// - Parameter handler: this object will receive all tracking events. The same object will not be added twice.
    ///                      The handler is retained by the Tracker.
    func append(handler: TrackingHandler) {
        guard !trackingHandlers.contains(where: { $0 === handler }) else { return }
        trackingHandlers.append(handler)
    }

    /// Deletes a handler, if it is registered. If not, this operation does nothing.
    ///
    /// - Parameter handler: previously registered handler
    func remove(handler: TrackingHandler) {
        if let handlerIndex = trackingHandlers.firstIndex(where: { $0 === handler }) {
            trackingHandlers.remove(at: handlerIndex)
        }
    }

    /// Propagates the tracked event to all registered event handlers.
    ///
    /// - Parameters:
    ///   - event: occurred event
    ///   - parameters: optional parameters that will be combined with the Trackable.parameters. These parameters
    ///                 will override any parameters from Trackable with the same key.
    func track(event: Trackable, parameters: [String: Any]? = nil) {
        var joinedParameters = event.parameters ?? [:]
        parameters?.forEach { joinedParameters[$0.key] = $0.value }
        let trackedParameters: [String: Any]? = joinedParameters.isEmpty ? nil : joinedParameters
        for handler in trackingHandlers {
            handler.track(event: event.eventName, parameters: trackedParameters)
        }
    }

    /// Propagates the user property to all registered event handlers.
    ///
    /// - Parameters:
    ///   - value: String value
    ///   - property: UserProperty
    func setUserProperty(_ value: String, for property: UserProperty) {
        for handler in trackingHandlers {
            handler.setUserProperty(value, for: property)
        }
    }
}

/// Concrete implementations of tracking systems should conform to this protocol to be registered with the Tracker.
protocol TrackingHandler: class {
    /// Track event with parameters.
    ///
    /// - Parameters:
    ///   - event: occurred event
    ///   - parameters: optional parameters
    func track(event: String, parameters: [String: Any]?)

    /// Set user property for tracking events.
    ///
    /// - Parameters:
    ///   - value: String value
    ///   - property: UserProperty
    func setUserProperty(_ value: String, for property: UserProperty)
}

/// Conform your enum to this protocol to use it as a user property.
protocol UserProperty {
    // Raw value of the enum (String)
    var rawValue: String { get }
}

/// Conform your enum to this protocol for it to be tracked with Tracker.
protocol Trackable {
    // Raw value of the enum (String)
    var rawValue: String { get }
    // Event type for tracking. Default value is `rawValue`
    var eventName: String { get }
    // Parameters to supply with the event. Default value is `nil`.
    var parameters: [String: Any]? { get }
}

extension Trackable {
    var eventName: String { return rawValue }
    var parameters: [String: Any]? { return nil }
}

protocol ScreenTrackingEvent: Trackable {}
