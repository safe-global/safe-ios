//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public extension String {

    var hasUppercaseLetter: Bool {
        return rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil
    }

    var hasDecimalDigit: Bool {
        return rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }

}
