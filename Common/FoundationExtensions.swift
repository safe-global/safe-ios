//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public extension String {

    var hasLetter: Bool {
        return rangeOfCharacter(from: CharacterSet.letters) != nil
    }

    var hasDecimalDigit: Bool {
        return rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }

    var hasNoTrippleChar: Bool {
        guard count > 2 else { return true }
        var previous = self.first!
        var sequenceLength = 1
        for c in dropFirst() {
            if c == previous {
                sequenceLength += 1
                if sequenceLength == 3 { return false }
            } else {
                previous = c
                sequenceLength = 1
            }
        }
        return true
    }

}

public extension SetAlgebra {

    func intersects(with other: Self) -> Bool {
        return !isDisjoint(with: other)
    }

}
