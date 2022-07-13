//
// Created by Dirk Jäckel on 08.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class DelegateWarningCalculator {
    private static let UNTRUSTED = true
    private static let TRUSTED = false

    // MultiSendTx is untrusted: operation = delegate
    // Safe Tx is untrusted: operation = delegate && 'to' is not 'known'
    // 'resolving name': 'to' object's .name is nil

    typealias MultiSendTx = SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    typealias AddressInfoIndex = SCGModels.AddressInfoIndex

    static func isUntrusted(txData: SCGModels.TxData?) -> Bool {
        guard let txData = txData else {
            return UNTRUSTED
        }

        if txData.trustedDelegateCallTarget == false {
            return UNTRUSTED
        } else if txData.trustedDelegateCallTarget == true {
            return TRUSTED
        }
        // else the 'trustedDelegateCallTarget' flag is nil

        // if multi-send
        if let data = txData.dataDecoded, data.method == "multiSend" {
            return isUntrusted(dataDecoded: data, addressInfoIndex: txData.addressInfoIndex)
        }

        return TRUSTED
    }

    static func isUntrusted(dataDecoded: SCGModels.DataDecoded?, addressInfoIndex: AddressInfoIndex?) -> Bool {
        guard let data = dataDecoded, let parameters = data.parameters else {
            return TRUSTED
        }

        // check if all parameters are trusted, recursively.
        let allParametersTrusted = parameters.allSatisfy { parameter in
            switch parameter.valueDecoded {

            case .multiSend(let multiSendTransactions):

                // all transactions must be trusted
                let allTransactionsTrusted = multiSendTransactions.allSatisfy { multiSendTx in

                    // checks each sub-transaction recursively
                    !isUntrusted(multiSendTx: multiSendTx, addressInfoIndex: addressInfoIndex)
                }
                // parameter is trusted when all sub-transactions are trusted.
                return allTransactionsTrusted

                    // if it's nil (.none) or not decoded, then we say it's trusted
            case .none, .unknown:
                return true // true means trusted in this case. Do not use UN/TRUSTED here
            }
        }

        let result = allParametersTrusted ? TRUSTED : UNTRUSTED

        return result
    }

    /// Multi Send transaction is potentially dangerous (untrusted) if it is a "delegate call"
    /// operation and the recipient (target) address, "to", does not have a name resolved.
    ///
    /// - Parameters:
    ///   - multiSendTx: multisend transaction
    ///   - addressInfoIndex: name index of addresses in the decoded transaction data
    /// - Returns: true if transaction is untrusted, false otherwise.
    static func isUntrusted(multiSendTx: MultiSendTx, addressInfoIndex: AddressInfoIndex?) -> Bool {
        let result = multiSendTx.operation == .delegate
        // Recursion: check sub-transactions if they are untrusted in case the 'self' is trusted
        return result || isUntrusted(dataDecoded: multiSendTx.dataDecoded, addressInfoIndex: addressInfoIndex)
    }
}
