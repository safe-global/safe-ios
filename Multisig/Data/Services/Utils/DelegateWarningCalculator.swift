//
// Created by Dirk Jäckel on 08.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// used to enhance txData to contain trustedDelegateCallTarget flags in every displayed tx (also multisend inner txs)
class DelegateWarningCalculator {
    static func addMissingTrustedDelegateCallTargets(txData: SCGModels.TxData) {

        // TODO check: if operation is DELEGATE then to-address must be in addressInfoIndex otherwise trustedDelegateCallTarget = false
        // if txData.to

        if txData.dataDecoded?.method == "multiSend" {
            guard let parameters = txData.dataDecoded?.parameters else {
                return
            }
            for parameter in parameters {
                if case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = parameter.valueDecoded {
                    print("Multisend: (\(multiSendTxs.count) actions)")
                    for var multiSendTx in multiSendTxs {
                        if multiSendTx.operation == .delegate {
                            print("Multisend: is DELEGATE, addressInfo: \(txData.addressInfoIndex?.values[multiSendTx.to]?.addressInfo)")
                            if txData.addressInfoIndex?.values[multiSendTx.to]?.addressInfo == nil {
                                print("Multisend: multiSendTx.trustedDelegateCallTarget = false")
                                multiSendTx.trustedDelegateCallTarget = false
                            } else {
                                print("Multisend: multiSendTx.trustedDelegateCallTarget = true")
                                multiSendTx.trustedDelegateCallTarget = true
                            }
                        }
                    }
                }
            }
        }
    }
}