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
        var current = self.first!
        var longestSiquence = 1
        for c in suffix(count - 1) {
            if c == current {
                longestSiquence += 1
                guard longestSiquence < 3 else { return false }
            } else {
                current = c
                longestSiquence = 1
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
