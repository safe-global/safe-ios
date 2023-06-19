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
    func track(event: Trackable, parameters: [String: Any]? = nil, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        var joinedParameters = event.parameters ?? [:]
        parameters?.forEach { joinedParameters[$0.key] = $0.value }
        let trackedParameters: [String: Any]? = joinedParameters.isEmpty ? nil : joinedParameters
        for handler in trackingHandlers {
            handler.track(event: event.eventName, parameters: trackedParameters, file: file, line: line, function: function)
        }
    }

    /// Propagates the user property to all registered event handlers.
    ///
    /// - Parameters:
    ///   - value: String value
    ///   - property: UserProperty
    func setUserProperty(_ value: String, for property: UserProperty, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        for handler in trackingHandlers {
            handler.setUserProperty(value, for: property, file: file, line: line, function: function)
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
    ///   - file: file name this was called from. Usually #file
    ///   - line: line in file this was called from. Usually #line
    ///   - function: function anme this was called from. Usually #function
    func track(event: String, parameters: [String: Any]?, file: StaticString, line: UInt, function: StaticString)

    /// Set user property for tracking events.
    ///
    /// - Parameters:
    ///   - value: String value
    ///   - property: UserProperty
    ///   - file: file name this was called from. Usually #file
    ///   - line: line in file this was called from. Usually #line
    ///   - function: function anme this was called from. Usually #function
    func setUserProperty(_ value: String, for property: UserProperty, file: StaticString, line: UInt, function: StaticString)

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
    static func trackEvent(_ event: TrackingEvent, parameters: [String: Any]? = nil, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        var parameters = parameters ?? [String: Any]()
        if shouldAddChainIdParam(for: event) && parameters["chain_id"] == nil {
            let chainId = try? Safe.getSelected()?.chain?.id ?? "none"
            parameters["chain_id"] = chainId
        }
        Tracker.shared.track(event: event, parameters: parameters, file: file, line: line, function: function)
    }

    private static func shouldAddChainIdParam(for event: TrackingEvent) -> Bool {
        event.rawValue.starts(with: "screen") ||
            [
                .userTransactionConfirmed,
                .userTransactionExecuteSubmitted,
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
        case .keystone:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysKeystone)
        case .web3AuthApple:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysWeb3AuthApple)
        case .web3AuthGoogle:
            Tracker.shared.setUserProperty("\(count)", for: TrackingUserProperty.numKeysWeb3AuthGoogle)
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
