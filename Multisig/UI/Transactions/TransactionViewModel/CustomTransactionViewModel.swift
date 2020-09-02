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
    var data: String
    var dataDecoded: TransactionData?

    override init() {
        dataLength = 0
        data = ""
        super.init()
    }

    override init(outgoing: Bool? = nil, transfer: TransferInfo, tx: Transaction, safe: SafeInfo) {
        dataLength = tx.data.map { $0.data.count } ?? 0
        data = tx.data?.description ?? ""
        dataDecoded = tx.dataDecoded
        super.init(outgoing: outgoing ?? true, transfer: transfer, tx: tx, safe: safe)
    }

    override class func viewModels(from tx: Transaction, info: SafeStatusRequest.Response) -> [TransactionViewModel] {
        let token =  App.shared.tokenRegistry.token(address: .ether)!
        let transfer = TransferInfo(ether: tx, info: info, token: token)
        return [CustomTransactionViewModel(transfer: transfer, tx: tx, safe: info)]
    }
}
