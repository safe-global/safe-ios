//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class Timer {

    public static func random(average: Double, maxDeviation: Double) -> Double {
        let amplitude = 2 * fabs(maxDeviation)
        let random0to1 = Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        return average + amplitude * (random0to1 - 0.5)
    }

    public static func wait(_ time: TimeInterval) {
        guard time > 0 else { return }
        if Thread.isMainThread {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: time))
        } else {
            usleep(UInt32(time * 1_000_000))
        }
    }

}
