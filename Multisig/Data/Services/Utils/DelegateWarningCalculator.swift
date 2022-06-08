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
        txData.trustedDelegateCallTarget = true

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
}
