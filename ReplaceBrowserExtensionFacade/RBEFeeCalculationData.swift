//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public struct RBEFeeCalculationData: Equatable {

    public var currentBalance: TokenData
    public var networkFee: TokenData
    public var balance: TokenData

    public init(currentBalance: TokenData,
                networkFee: TokenData,
                balance: TokenData) {
        self.currentBalance = currentBalance
        self.networkFee = networkFee
        self.balance = balance
    }

}
