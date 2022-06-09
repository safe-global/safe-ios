//
// Created by Dirk Jäckel on 08.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// used to enhance txData to contain trustedDelegateCallTarget flags in every displayed tx (also multisend inner txs)
class DelegateWarningCalculator {

    static func addMissingTrustedDelegateCallTargets(txData: inout SCGModels.TxData) {

        // TODO check: if operation is DELEGATE then to-address must be in addressInfoIndex otherwise trustedDelegateCallTarget = false
        // if txData.to

        // for testing. This should replace any false value with true ad thus fail the first test
        // txData.trustedDelegateCallTarget = true

        guard var decoded = txData.dataDecoded, decoded.method == "multiSend", let parameters = decoded.parameters else {
            return
        }

        decoded.parameters = parameters.map { parameter in
            guard case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = parameter.valueDecoded else {
                return parameter
            }

            let modifiedMultiSendTxList: [SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx] = multiSendTxs.map { multiSendTx in
                var modifiedMultiSendTx = multiSendTx

                let isUntrusted =
                    multiSendTx.operation == .delegate && txData.addressInfoIndex?.values[multiSendTx.to]?.addressInfo == nil

                modifiedMultiSendTx.trustedDelegateCallTarget = !isUntrusted

                if isUntrusted {
                    txData.trustedDelegateCallTarget = false
                }
                
                return modifiedMultiSendTx
            }

            var modifiedParameter = parameter
            modifiedParameter.valueDecoded = SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(modifiedMultiSendTxList)
            return modifiedParameter
        }

        txData.dataDecoded = decoded

        return
    }


    private static let UNTRUSTED = true
    private static let TRUSTED = false

    // MultiSendTx is untrusted: operation = delegate && 'to' address is not 'known'
        // 'resolving the name': look up in the address info index
    // Safe Tx is untrusted: operation = delegate && 'to' is not 'known'
        // 'resolving name': 'to' object's .name is nil

    typealias MultiSendTx = SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    typealias AddressInfoIndex = SCGModels.AddressInfoIndex


    static func isUntrusted(txData: SCGModels.TxData) -> Bool {
        if txData.trustedDelegateCallTarget == false {
            return UNTRUSTED
        } else if txData.trustedDelegateCallTarget == true {
            return TRUSTED
        }
        // else the 'trustedDelegateCallTarget' flag is nil

        // if multi-send
        if let data = txData.dataDecoded, data.method == "multiSend" {
            return isUntrusted(data: data, addressIndex: txData.addressInfoIndex)
        } else {
            // check safe tx
            let untrusted = txData.operation == .delegate && txData.to.addressInfo.name == nil
            let result = untrusted ? UNTRUSTED : TRUSTED
            return result
        }
    }


    static func isUntrusted(data: SCGModels.DataDecoded?, addressIndex: AddressInfoIndex?) -> Bool {
        guard let data = data, let parameters = data.parameters else { return TRUSTED }

        // check if all parameters are trusted, recursively.
        let allParametersTrusted = parameters.allSatisfy { parameter in
            switch parameter.valueDecoded {

            case .multiSend(let multiSendTransactions):

                // all transactions must be trusted
                let allTransactionsTrusted = multiSendTransactions.allSatisfy { multiSendTx in

                    // checks each sub-transaction recursively
                    !isUntrusted(tx: multiSendTx, addressIndex: addressIndex)
                }
                // parameter is trusted when all sub-transactions are trusted.
                return allTransactionsTrusted

            // if it's nil (.none) or not decoded, then we say it's trusted
            case .none, .unknown:
                return true
            }
        }

        let result = allParametersTrusted ? TRUSTED : UNTRUSTED

        return result
    }

    /// Multi Send transaction is potentially dangerous (untrusted) if it is a "delegate call"
    /// operation and the recipient (target) address, "to", does not have a name resolved.
    ///
    /// If the multisend transaction is itself a multi-send
    ///
    /// - Parameters:
    ///   - tx: multisend transaction
    ///   - addressIndex: name index of addresses in the decoded transaction data
    /// - Returns: true if transaction is untrusted, false otherwise.
    static func isUntrusted(tx: MultiSendTx, addressIndex: AddressInfoIndex?) -> Bool {
        let result = tx.operation == .delegate && addressIndex?.values[tx.to]?.addressInfo == nil
        // Recursion: check sub-transactions if they are untrusted in case the 'self' is trusted
        return result || isUntrusted(data: tx.dataDecoded, addressIndex: addressIndex)
    }

}
