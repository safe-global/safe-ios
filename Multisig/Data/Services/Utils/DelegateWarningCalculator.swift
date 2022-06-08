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

        if txData.dataDecoded?.method == "multiSend" {
            guard let parameters = txData.dataDecoded?.parameters else {
                return
            }
            for var parameter in parameters {
                if case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = parameter.valueDecoded {
                    print("--> Multisend: (\(multiSendTxs.count) actions)")
                    for var multiSendTx in multiSendTxs {
                        if multiSendTx.operation == .delegate {
                            print("--> Multisend: is DELEGATE, addressInfo: \(txData.addressInfoIndex?.values[multiSendTx.to]?.addressInfo)")
                            if txData.addressInfoIndex?.values[multiSendTx.to]?.addressInfo == nil {
                                print("--> Multisend: multiSendTx.trustedDelegateCallTarget = false")
                                multiSendTx.trustedDelegateCallTarget = false
                                // TODO: also set surrounding tx trustedDelegateCallTarget to false
                                txData.trustedDelegateCallTarget = false
                            } else {
                                print("--> Multisend: multiSendTx.trustedDelegateCallTarget = true")
                                multiSendTx.trustedDelegateCallTarget = true
                            }
                        } else {
                            print("--> Multisend: multiSendTx.trustedDelegateCallTarget = true (no delegate)")
                            multiSendTx.trustedDelegateCallTarget = true
                        }
                        print("--> Multisend TX trustedDelegateCallTarget: \(multiSendTx.trustedDelegateCallTarget!)")
                    }
                }
            }
        }
    }
}