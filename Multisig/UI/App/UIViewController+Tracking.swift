//
//  UIViewController + Tracking.swift
//  Multisig
//
//  Created by Moaaz on 11/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIViewController {
    func trackEvent(_ event: TrackingEvent, parameters: [String: Any]? = nil) {
        Tracker.shared.track(event: event, parameters: parameters)
    }
}
