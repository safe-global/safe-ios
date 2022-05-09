//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

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

 Then, from a view controller's `viewDidAppear` method call `Tracker.trackEvent` method on UIViewController:

     override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         Tracker.trackEvent(MyMenuEvent.eventName)
     }

 Finally, you can subclass the Tracker for testing purposes. In that case, replace the singleton instance stored in
 the `shared` property.

 */
class Tracker {
    /// Singleton instance.
    fileprivate static var shared = Tracker()

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

    /// Specifies if tracking should be enabled for tracking handlers
    ///
    /// - Parameter value: Bool value to indicate if tracking should be enabled
    func setTrackingEnabled(_ value: Bool) {
        for handler in trackingHandlers {
            handler.setTrackingEnabled(value)
        }
    }
}

/// Concrete implementations of tracking systems should conform to this protocol to be registered with the Tracker.
protocol TrackingHandler: AnyObject {
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

    /// Specifies if tracking should be enabled for tracking handler
    ///
    /// - Parameter value: Bool value to indicate if tracking should be enabled
    func setTrackingEnabled(_ value: Bool)
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

extension Tracker {
    static func trackEvent(_ event: TrackingEvent, parameters: [String: Any]? = nil) {
        var parameters = parameters ?? [String: Any]()
        if shouldAddChainIdParam(for: event) && parameters["chain_id"] == nil {
            let chainId = try? Safe.getSelected()?.chain?.id ?? "none"
            parameters["chain_id"] = chainId
        }
        Tracker.shared.track(event: event, parameters: parameters)
    }
    
    static func parametersWithWalletName(_ walletName: String, parameters: [String: Any]? = nil) -> [String: Any] {
        var parameters = parameters ?? [String: Any]()
        var walletName = walletName
        if walletName.count > 100 {
            walletName = String(walletName.prefix(100))
        }
        parameters["wallet"] = walletName
        return parameters
    }

    private static func shouldAddChainIdParam(for event: TrackingEvent) -> Bool {
        event.rawValue.starts(with: "screen") ||
            [
                .transactionDetailsTransactionConfirmed,
                .transactionDetailsTxConfirmedWC,
                .transactionDetailsTransactionRejected,
                .transactionDetailsTxRejectedWC,
                .dappConnectedWithScanButton,
                .dappConnectedWithUniversalLink,
                .selectDapp,
                .collectiblesOpenInWeb,
                .addOwnerFromSettings,
                .replaceOwnerFromSettings,
                .userRemoveOwnerFromSettings
            ].contains(event)
    }

    static func setNumSafesUserProperty(_ count: Int) {
        Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numSafes)
    }

    static func setPushInfo(_ status: String) {
        Tracker.shared.setUserProperty(status, for: TrackingUserProperty.pushInfo)
    }

    static func setNumKeys(_ count: Int, type: KeyType) {
        switch type {
        case .deviceGenerated:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysGenerated)
        case .deviceImported:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysImported)
        case .walletConnect:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysWalletConnect)
        case .ledgerNanoX:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysLedgerNanoX)
        }
    }

    static func setPasscodeIsSet(to status: Bool) {
        let property = status ? "true" : "false"
        Tracker.shared.setUserProperty(property, for: TrackingUserProperty.passcodeIsSet)
    }

    static func setWalletConnectForDappsEnabled(_ enabled: Bool) {
        let property = enabled ? "true" : "false"
        Tracker.shared.setUserProperty(property, for: TrackingUserProperty.walletConnectForDappsEnabled)
    }

    static func append(handler: TrackingHandler) {
        Tracker.shared.append(handler: handler)
    }

    static func setTrackingEnabled(_ value: Bool) {
        Tracker.shared.setTrackingEnabled(value)
    }
}
