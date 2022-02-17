//
// Created by Dmitry Bespalov on 16.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WebConnectionSignatureRequest: WebConnectionRequest {
    var account: Address
    var message: Data

    init(id: WebConnectionRequestId?, method: String?, error: String?, json: String?, status: WebConnectionRequestStatus, connectionURL: WebConnectionURL?, createdDate: Date?, account: Address, message: Data) {
        self.account = account
        self.message = message
        super.init(id: id, method: method, error: error, json: json, status: status, connectionURL: connectionURL, createdDate: createdDate)
    }

    static func response(signature: Data) -> DataString {
        DataString(signature)
    }
}
