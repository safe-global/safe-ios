//
//  TransactionIntegrationTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 20.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest

class TransactionIntegrationTests: XCTestCase {
    // execute tx
        // with a private key
        // with a ledger key
        // with a WC key

        // using eth_sign
        // using eth_personalSign
        // using eth_signTypedData (v1, v2, v3, v4)?

        // with enough confirmations
        // with not enough confirmations

        // gas estimation from chain
        // gas estimation from gas station

        // from CGW transaction details
        // from WC transaction details

        // safe implementation version
            // 0.0.1
            // 0.0.2
            // 1.0.0
            // 1.1.1
            // 1.3.0

        // with operation
            // call
            // delegate call

        // types:
            // send native coin
            // send erc20
            // send erc721
            // change safe settings
                // add owner with changing threshold
                // remove owner with changing threshold
                // swap owner
                // change threshold
                // change implementation
                // set fallback handler
                // enable module
                // disable module
            // module transaction
            // custom contract call
            // rejection transaction
            // approve hash
            // multi-send
            // contract deployment transaction
                // safe deployment transaction
                // nft deployment transaction
                // erc20 deployment transaction

        // chains:
            // Ethereum
            // xDai
            // Polygon
            // Binance Smart Chain
            // Energy Web Chain
            // Volta
            // Arbitrum
            // Avalanche
            // Goerli
            // Rinkeby
}

// deploy a safe of a version X
