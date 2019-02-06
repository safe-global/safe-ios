//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol RBEStarter {

    func create() -> RBETransactionID
    func estimate(transaction: RBETransactionID) -> RBEEstimationResult
    func start(transaction: RBETransactionID) throws

}

public typealias RBETransactionID = String

public struct RBEEstimationResult: Equatable, CustomDebugStringConvertible {

    public var feeCalculation: RBEFeeCalculationData?
    public var error: Error?

    public var debugDescription: String {
        return "RBEEstimationResult{feeCalculation: \(String(describing: feeCalculation)), error: \(String(describing: error))}"
    }

    public init(feeCalculation: RBEFeeCalculationData?, error: Error?) {
        self.feeCalculation = feeCalculation
        self.error = error
    }

    public static func == (lhs: RBEEstimationResult, rhs: RBEEstimationResult) -> Bool {
        return lhs.feeCalculation == rhs.feeCalculation &&
            String(describing: lhs.error) == String(describing: rhs.error)
    }

}
