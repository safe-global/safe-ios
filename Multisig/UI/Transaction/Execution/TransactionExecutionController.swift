//
//  TransactionExecutionController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity

class TransactionExecutionController {
    private var safe: Safe
    private var chain: Chain
    private var transaction: SCGModels.TransactionDetails

    var chainId: String {
        chain.id!
    }

    var selectedKeyIndex: Int? {
        executionKeys().isEmpty ? nil : 0
    }

    init(safe: Safe, chain: Chain, transaction: SCGModels.TransactionDetails) {
        self.safe = safe
        self.chain = chain
        self.transaction = transaction
    }

    // returns the execution keys valid for executing this transaction
    func executionKeys() -> [KeyInfo] {
        // all keys that can sign this tx on its chain.
            // currently, only wallet connect keys are chain-specific, so we filter those out.
        guard let allKeys = try? KeyInfo.all(), !allKeys.isEmpty else {
            return []
        }

        let validKeys = allKeys.filter { keyInfo in
            // if it's a wallet connect key which chain doesn't match then do not use it
            if keyInfo.keyType == .walletConnect,
               let data = keyInfo.metadata,
               let connection = KeyInfo.WalletConnectKeyMetadata.from(data: data),
               // when chainId is 0 then it is 'any' chain
               connection.walletInfo.chainId != 0 &&
                String(describing: connection.walletInfo.chainId) != chain.id {
                return false
            }
            // else use the key
            return true
        }

        return validKeys
    }

    func selectKey(_ key: KeyInfo?) {
        
    }

    var selectedKey: (key: KeyInfo, balance: AccountBalanceUIModel)?
    var requiredBalance: Sol.UInt256 = 0

    let keySelectionPolicy = OwnerKeySelectionPolicy()

    // cancellable process to find a default execution key
    func findDefaultKey(completion: @escaping () -> Void) -> URLSessionTask? {
        // use safe's owner addresses
        let ownerAddresses = safe.ownersInfo?.map { $0.address } ?? []

        // make database query to get all keys
        let keys = executionKeys()

        // make network request to fetch balances
        let balanceLoader = DefaultAccountBalanceLoader(chain: chain)
        balanceLoader.requiredBalance = requiredBalance

        let task = balanceLoader.loadBalances(for: keys) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                // if request cancelled, do nothing, don't call completion.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                // if request fails with some error treat as if balances are set to 0
                let balances: [AccountBalanceUIModel] = .init(
                    repeating: AccountBalanceUIModel(displayAmount: "", isEnabled: true), count: keys.count)
                self.findDefaultKey(keys: keys, balances: balances, ownerAddresses: ownerAddresses)
                completion()

            case .success(let balances):
                self.findDefaultKey(keys: keys, balances: balances, ownerAddresses: ownerAddresses)

                completion()
            }
        }
        return task
    }

    private func findDefaultKey(
        keys: [KeyInfo],
        balances: [AccountBalanceUIModel],
        ownerAddresses: [Address]
    ) {
        assert(keys.count == balances.count)
        let candidates = zip(keys, balances).map { key, balance in
            OwnerKeySelectionPolicy.KeyCandidate(
                key: key,
                balance: balance.amount ?? 0,
                isOwner: ownerAddresses.contains(key.address))
        }

        let bestCandidate = self.keySelectionPolicy.defaultExecutionKey(
            in: candidates,
            requiredAmount: self.requiredBalance
        )
        if let bestCandidate = bestCandidate {
            let result = zip(keys, balances).first { $0.0 == bestCandidate.key }!
            self.selectedKey = result
        } else {
            self.selectedKey = nil
        }
    }

}
