//
//  TransactionExecutionController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class TransactionExecutionController {
    private var safe: Safe!
    private var chain: Chain!
    private var transaction: SCGModels.TransactionDetails!

    var chainId: String {
        chain.id!
    }

    var selectedKeyIndex: Int? {
        executionKeys().isEmpty ? nil : 0
    }

    init(safe: Safe?, chain: Chain?, transaction: SCGModels.TransactionDetails) {
        self.safe = safe
        self.chain = chain
        self.transaction = transaction
    }
    // returns the execution keys valid for executing this transaction
    func executionKeys() -> [KeyInfo] {
        guard let safe = safe, let chain = safe.chain else {
            return []
        }

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
}
