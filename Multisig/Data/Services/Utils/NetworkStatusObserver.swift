//
//  NetworkStatusObserver.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.03.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import SystemConfiguration
import CoreFoundation

/// Class that can observe a network host reachability status and post
/// notifications when the status changes.
///
/// All methods MUST be called on main thread.
class NetworkHostStatusObserver {

    /// Host to observe
    let host: String

    private var target: SCNetworkReachability?

    enum Status {
        case unknown, online, offline

        fileprivate static func from(reachabilityFlags: SCNetworkReachabilityFlags) -> Self {
            // if reachable and not need to connect
            let reachableWithoutConnection = reachabilityFlags.contains(.reachable) && !reachabilityFlags.contains(.connectionRequired)
            let reachableWithoutIntervention = reachabilityFlags.contains(.reachable) && !reachabilityFlags.contains(.interventionRequired) &&
                (reachabilityFlags.contains(.connectionOnTraffic) || reachabilityFlags.contains(.connectionOnDemand))

            if reachableWithoutConnection || reachableWithoutIntervention {
                return .online
            } else {
                return .offline
            }
        }
    }

    private (set) var status: Status  = .unknown

    /// Constructor
    /// - Parameter host: Pass the URL's host name to observe.
    init(host: String) {
        self.host = host
    }

    /// Starts asynchronous observing of the network host.
    ///   - Posts `networkHostUnreachable` when the host becomes unreachable or
    /// after getting first update of the reachability (if it's unreachable).
    ///   - Posts `networkHostReachable` when the host becomes reachable after
    /// being unreachable
    func startObserving() {
        dispatchPrecondition(condition: .onQueue(.main))

        // create target
        stopObserving()
        target = SCNetworkReachabilityCreateWithName(nil, host)
        guard let target = target else {
            logError()
            return
        }

        //      schedule on the main thread's run loop
        let scheduleSuccess = SCNetworkReachabilityScheduleWithRunLoop(target, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        guard scheduleSuccess else {
            logError()
            return
        }

        // wrap pointer to self into context info in order to get
        // reference to `self` from the C callback closure
        let info = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        var context = SCNetworkReachabilityContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)

        let callbackSuccess = SCNetworkReachabilitySetCallback(target, { (_, flags, context) in
            // unwrap self from context info
            guard let ctx = context else { return }
            let observer = Unmanaged<NetworkHostStatusObserver>.fromOpaque(ctx).takeUnretainedValue()

            observer.updateStatus(flags: flags)
        }, &context)

        guard callbackSuccess else {
            logError()
            return
        }
    }

    private func updateStatus(flags: SCNetworkReachabilityFlags) {
        let oldStatus = status
        let newStatus = Status.from(reachabilityFlags: flags)
        status = newStatus

        // Notify listeners
        switch (oldStatus, newStatus) {
        case (.unknown, .offline), (.online, .offline):
            NotificationCenter.default.post(name: .networkHostUnreachable, object: self, userInfo: ["host": host])
        case (.offline, .online):
            NotificationCenter.default.post(name: .networkHostReachable, object: self, userInfo: ["host": host])
        default:
            break
        }
    }

    private func logError(line: UInt = #line, file: StaticString = #file) {
        let code = SCError()
        let message = SCErrorString(code)
        LogService.shared.error("\(file):\(line): Network reachability failure: '\(message)', Code \(code)")
    }

    /// Stops observing network host reachability
    func stopObserving() {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let target = target else { return }
        //      delete the callback
        SCNetworkReachabilitySetCallback(target, nil, nil)

        //      unschedule from run loop
        SCNetworkReachabilityUnscheduleFromRunLoop(target, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.target = nil
        assert(self.target == nil)
    }

    /// Gets current reachability status without updating the object's status
    func getStatus() -> Status? {
        guard let target = SCNetworkReachabilityCreateWithName(nil, host) else {
            logError()
            return nil
        }
        var outFlags: SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(target, &outFlags)
        let status = Status.from(reachabilityFlags: outFlags)
        return status
    }
}
