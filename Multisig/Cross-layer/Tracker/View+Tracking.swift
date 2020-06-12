//
//  View+Tracking.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension View {
    /// Convenience method for tracking event from a View
    ///
    /// - Parameters:
    ///   - event: occurred event
    ///   - parameters: optional parameters
    func trackEvent(_ event: TrackingEvent, parameters: [String: Any]? = nil) {
        Tracker.shared.track(event: event, parameters: parameters)
    }
}
