//
//  SafTransactionService.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Safe transaction service will be used only by WalletConnect prototype for a while
class SafeTransactionService {
    static func supports(networkId: String) -> Bool {
        url(networkId: networkId) != nil
    }

    static func url(networkId: String) -> URL? {
        switch networkId {
        case Network.ChainID.ethereumMainnet: return URL(string: "https://safe-transaction.gnosis.io/api/")!
        case Network.ChainID.ethereumRinkeby: return URL(string: "https://safe-transaction.rinkeby.gnosis.io/api/")!
        case Network.ChainID.polygon: return URL(string: "https://safe-transaction.polygon.gnosis.io/api/")!
        case Network.ChainID.xDai: return URL(string: "https://safe-transaction.xdai.gnosis.io/api/")!
        default: return nil
        }
    }

    @discardableResult
    static func execute<T: JSONRequest>(request: T, networkId: String) throws -> T.ResponseType {
        let httpClient = JSONHTTPClient(url: url(networkId: networkId)!, logger: LogService.shared)
        httpClient.jsonDecoder.dateDecodingStrategy = .backendDateDecodingStrategy
        return try httpClient.execute(request: request)
    }
}
