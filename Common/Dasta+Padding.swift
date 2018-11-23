//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public extension Data {

    /// Pads data with `value` from the left to total width of `count`
    ///
    /// - Parameters:
    ///   - count: total padded with=
    ///   - value: padding value, default is 0
    /// - Returns: padded data of size `count`
    func leftPadded(to count: Int, with value: UInt8 = 0) -> Data {
        if self.count >= count { return self }
        return Data(repeating: value, count: count - self.count) + self
    }

    func rightPadded(to count: Int, with value: UInt8 = 0) -> Data {
        if self.count >= count { return self }
        return self + Data(repeating: value, count: count - self.count)
    }

    func endTruncated(to count: Int) -> Data {
        guard self.count > count else { return self }
        return Data(self[0..<count])
    }

}
