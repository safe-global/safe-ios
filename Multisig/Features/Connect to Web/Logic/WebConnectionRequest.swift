//
// Created by Dmitry Bespalov on 11.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Represents an incoming request
struct WebConnectionRequest {
    var id: WebConnectionRequestId
}

struct WebConnectionRequestId {
    var intValue: Int?
    var stringValue: String?
    var doubleValue: Double?

    init(intValue: Int?) {
        self.intValue = intValue
    }

    init(stringValue: String?) {
        self.stringValue = stringValue
    }

    init(doubleValue: Double?) {
        self.doubleValue = doubleValue
    }
}

struct WebConnectionSignatureRequest {
    var message: Data
    var account: Address
}
