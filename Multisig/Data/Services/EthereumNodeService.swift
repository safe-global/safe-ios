//
//  EthereumNodeService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

class EthereumNodeService {

    var url: URL
    let web3: Web3

    init(url: URL) {
        self.url = url
        web3 = Web3(rpcURL: url.absoluteString)
    }

    func eth_call(to: Address, data: Data) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)

        var result: Web3Response<EthereumData>!
        web3.eth.call(call: EthereumCall(to: try EthereumAddress(to.data), data: EthereumData(Array(data))),
                      block: EthereumQuantityTag(tagType: .latest),
                      response: { result = $0; semaphore.signal() })
        semaphore.wait()

        if let error = result.error {
            throw error
        } else if let data = result.result {
            return Data(data.bytes)
        } else {
            return Data()
        }
    }

}

extension Web3Response.Error : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let error):
            return error?.localizedDescription ?? "Connection Failed"
        case .emptyResponse:
            return "Empty response"
        case .requestFailed(let error):
            return error?.localizedDescription ?? "Request failed"
        case .serverError(let error):
            return error?.localizedDescription ?? "Server Error"
        case .decodingError(let error):
            return error?.localizedDescription ?? "Decoding Error"
        }
    }
}
