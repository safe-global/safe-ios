//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public class FeeCalculationError: NSError {

    public static let domain = "io.gnosis.safe.rbe"

    enum Description {
        static let insufficientBalance = LocalizedString("fee_calculation.error.insufficient_balance",
                                                         comment: "Insufficient funds.\nPlease add ETH to your Safe.")

    }
    public enum Code: Int {
        case insufficientBalance
    }

    public static let insufficientBalance =
        FeeCalculationError(domain: FeeCalculationError.domain,
                            code: Code.insufficientBalance.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: Description.insufficientBalance])
}
