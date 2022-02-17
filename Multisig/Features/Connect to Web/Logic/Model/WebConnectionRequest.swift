//
// Created by Dmitry Bespalov on 11.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

/// Represents an incoming request
class WebConnectionRequest {
    var id: WebConnectionRequestId?
    var method: String?
    var error: String?
    var json: String?
    var status: WebConnectionRequestStatus = .initial
    var connectionURL: WebConnectionURL?
    var createdDate: Date?

    init(id: WebConnectionRequestId?, method: String?, error: String?, json: String?, status: WebConnectionRequestStatus, connectionURL: WebConnectionURL?, createdDate: Date?) {
        self.id = id
        self.method = method
        self.error = error
        self.json = json
        self.status = status
        self.connectionURL = connectionURL
        self.createdDate = createdDate
    }
}

struct WebRequestIdentifier: Hashable {
    var connectionURL: WebConnectionURL
    var requestId: WebConnectionRequestId

    init(_ connectionURL: WebConnectionURL, _ requestId: WebConnectionRequestId) {
        self.connectionURL = connectionURL
        self.requestId = requestId
    }
}

enum WebConnectionRequestStatus: Int16 {
    case initial
    case pending
    case success
    case failed
    case unknown
}

struct WebConnectionRequestId: Hashable {
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

extension WebConnectionRequest {
    typealias ErrorCode = ResponseError
}
