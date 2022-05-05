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

    func addOwnerWithThresholdTransaction(safe: Safe, safeTxGas: UInt256String?, nonce: UInt256String, owner: Address, threshold: Int) -> Transaction? {
        guard let data = addOwnerWithThresholdData(owner: owner, threshold: threshold) else { return nil }
        let tx = Transaction(safeAddress: safe.addressValue,
                             chainId: safe.chain!.id!,
                             toAddress: safe.addressValue,
                             contractVersion: safe.contractVersion!,
                             amount: "0",
                             data: data,
                             safeTxGas: safeTxGas ?? "0",
                             nonce: nonce)

        return tx
    }

    func addOwnerWithThresholdData(owner: Address, threshold: Int) -> Data? {
        guard let owner = Sol.Address.init(maybeData:owner.data32) else { return nil }
        let threshold = Sol.UInt256.init(threshold)
        return GnosisSafe_v1_3_0.addOwnerWithThreshold(owner: owner, _threshold: threshold).encode()
    }

    func replaceOwner(safe: Safe, oldOwner: Address, newOwner: Address, safeTxGas: UInt256String?, nonce: UInt256String) -> Transaction? {
        guard let data = replaceOwnerData(oldOwner: oldOwner, newOwner: newOwner) else { return nil }
        let tx = Transaction(safeAddress: safe.addressValue,
                             chainId: safe.chain!.id!,
                             toAddress: safe.addressValue,
                             contractVersion: safe.contractVersion!,
                             amount: "0",
                             data: data,
                             safeTxGas: safeTxGas ?? "0",
                             nonce: nonce)

        return tx
    }

    func replaceOwnerData(oldOwner: Address, newOwner: Address) -> Data? {
        guard let newOwner = Sol.Address.init(maybeData:newOwner.data32),
              let oldOwner = Sol.Address.init(maybeData:oldOwner.data32) else { return nil }
        return GnosisSafe_v1_3_0.swapOwner(prevOwner: oldOwner, oldOwner: oldOwner, newOwner: newOwner).encode()
    }

    func proposeTransaction(transaction: Transaction,
                            sender: Address,
                            chainId: String,
                            signature: String,
                            completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        let task = App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                                                                sender: AddressString(sender),
                                                                signature: signature,
                                                                chainId: chainId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                switch result {
                case .failure(let error):
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        // Estimation was canceled, ignore.
                        return
                    }

                default: break
                }

                completion(result)
            }
        }
        return task
    }
}
