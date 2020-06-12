//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import Common

public final class FirebaseTrackingHandler: TrackingHandler {

    private let reservedNames: [String] = [
        "ad_activeview",
        "ad_click",
        "ad_exposure",
        "ad_impression",
        "ad_query",
        "adunit_exposure",
        "app_clear_data",
        "app_remove",
        "app_update",
        "error",
        "first_open",
        "in_app_purchase",
        "notification_dismiss",
        "notification_foreground",
        "notification_open",
        "notification_receive",
        "os_update",
        "screen_view",
        "session_start",
        "user_engagement"
    ]
    private let reservedPrefixes: [String] = [
        "firebase_",
        "google_",
        "ga_"
    ]
    private let nameLengthRange = (1...40)
    private let nameBodyCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    private let nameHeadCharacterSet = CharacterSet.letters
    private let maxParameterCount = 25
    private let stringParameterLengthRange = (1...100)

    public init() {}

    /// Tracks an event with parameters, verifying that event name, parameter count, parameter names and values
    /// are conforming to Firebase's limitations specified in the FIRAnalytics.h
    ///
    /// - Parameters:
    ///   - event: event name
    ///   - parameters: parameters to supply with the event
    public func track(event: String, parameters: [String: Any]?) {
        // check event name
        assert(!reservedNames.contains(event), "reserved name: \(event)")
        check(name: event)

        // check parameters
        if let parameters = parameters {
            assert(parameters.count <= maxParameterCount, "Too many parameters: \(parameters.count)")

            for (name, value) in parameters {
                check(name: name)
                assert(value as? NSString != nil || value as? NSNumber != nil,
                       "Event parameter value \(value) for key \(name) is of unsupported type: \(type(of: value))")

                if let stringValue = value as? NSString {
                    assert(stringParameterLengthRange.contains(stringValue.length),
                           "Event parameter value \(stringValue) for key \(name) is too long: \(stringValue.length)")
                    checkPrefix(value: stringValue as String)
                }
            }
        }
        Analytics.logEvent(event, parameters: parameters)
    }

    /// Verifies that the name is correct.
    ///
    /// Criteria:
    ///   1. Within allowed length
    ///   2. First characters and other characters are from allowed characters
    ///   3. Does not use preserved prefix
    ///
    /// - Parameter name: string to be used as event name or parameter name
    private func check(name: String) {
        assert(nameLengthRange.contains(name.count),
               "name length is \(name.count)")
        assert(name.rangeOfCharacter(from: nameBodyCharacterSet.inverted) == nil,
               "name contains forbidden characters: \(name)")
        assert(String(name.first!).rangeOfCharacter(from: nameHeadCharacterSet.inverted) == nil,
               "name starts with forbidden character: \(name)")
        checkPrefix(value: name)
    }

    /// Verifies that the value is correct
    ///
    /// Criteria:
    ///   1. Does not use preserved prefix
    ///
    /// - Parameter value: string to use as parameter value or event name
    private func checkPrefix(value: String) {
        assert(!reservedPrefixes.contains { value.starts(with: $0) }, "reserved prefix in the value: \(value)")
    }

}
