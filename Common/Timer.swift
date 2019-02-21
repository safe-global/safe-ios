//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Timer is used for delaying current thread's execution and calculating random time offsets for
/// simulation of network delays.
public class Timer {

    /// Calculates uniform random value within (average - maxDeviation, average + maxDeviation) range.
    ///
    /// - Parameters:
    ///   - average: average point to generate random number around
    ///   - maxDeviation: maximum range of values deviating from average
    /// - Returns: random value
    public static func random(average: Double, maxDeviation: Double) -> Double {
        let amplitude = 2 * fabs(maxDeviation)
        let random0to1 =  Double.random(in: 0..<1)
        return average + amplitude * (random0to1 - 0.5)
    }

    /// Waits current thread for the specified time interval
    ///
    /// - Parameter time: time to wait for, in seconds.
    public static func wait(_ time: TimeInterval) {
        guard time > 0 else { return }
        if Thread.isMainThread {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: time))
        } else {
            usleep(UInt32(time * 1_000_000))
        }
    }

}
