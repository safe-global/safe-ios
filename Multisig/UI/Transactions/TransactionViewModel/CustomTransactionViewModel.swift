//
//  CustomTransactionViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class CustomTransactionViewModel: TransferTransactionViewModel {
    var dataLength: Int

    override init() {
        dataLength = 0
        super.init()
    }

    init(_ tx: Transaction, _ safe: SafeStatusRequest.Response) {
        dataLength = tx.data.map { $0.data.count } ?? 0
        let safeAddress = tx.safe?.address ?? safe.address.address
        let from = safeAddress
        let to = tx.to?.address ?? .zero
        let amount = tx.value?.value ?? 0
        let tokenAddress = AddressRegistry.ether
        super.init(
            from: from,
            to: to,
            safe: safeAddress,
            erc721: false,
            value: amount,
            tokenAddress: tokenAddress,
            date: nil,
            status: nil,
            tx: tx,
            safeInfo: safe)
    }

}
