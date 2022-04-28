//
//  SafeOwnerEditingController.swift
//  Multisig
//
//  Created by Moaaz on 4/26/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import SafeAbi

class SafeTransactionController {
    static let shared = SafeTransactionController()

    private init() { }

    func addOwnerWithThresholdTransaction(safe: Safe, safeTxGas: UInt256String?, nonce: UInt256String, owner: Address, threshold: UInt256) -> Transaction? {
        guard let owner = Sol.Address.init(maybeData:owner.data32),
              let threshold = try? Sol.UInt256.init(threshold.data32) else { return nil }
        let addOwnerABI = GnosisSafe_v1_3_0.addOwnerWithThreshold(owner: owner, _threshold: threshold).encode()
        return Transaction.settingsChangeTransaction(safeAddress: safe.addressValue,
                                                     data: addOwnerABI,
                                                     safeTxGas: safeTxGas ?? "0",
                                                     nonce: nonce,
                                                     safeVersion: safe.contractVersion!,
                                                     chainId: safe.chain!.id!)
    }

    func proposeTransaction(transaction: Transaction,
                            sender: Address,
                            chainId: String,
                            signature: String,
                            completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) {
        App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                                                                sender: AddressString(sender),
                                                                signature: signature,
                                                                chainId: chainId) { result in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) {
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            // Estimation was canceled
                        } else {
                            App.shared.snackbar.show(error: GSError.error(description: "Failed to create transaction", error: error))
                        }
                    case .success(_):
                        break
                    }

                    completion(result)
                }
            }
        }
    }
}
