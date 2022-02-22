//
// Created by Dmitry Bespalov on 18.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Ethereum

class WebConnectionSendTransactionRequest: WebConnectionRequest {
    var transaction: EthTransaction

    init(id: WebConnectionRequestId?, method: String?, error: String?, json: String?, status: WebConnectionRequestStatus, connectionURL: WebConnectionURL?, createdDate: Date?, transaction: EthTransaction) {
        self.transaction = transaction
        super.init(id: id, method: method, error: error, json: json, status: status, connectionURL: connectionURL, createdDate: createdDate)
    }
}
