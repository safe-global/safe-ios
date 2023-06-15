//
//  EthereumNodeService.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SafeWeb3

class EthereumNodeService {

    init() { }

    func eth_call(to: Address, rpcURL: URL, data: Data) throws -> Data {
        let web3 = Web3(rpcURL: rpcURL.absoluteString)
        let semaphore = DispatchSemaphore(value: 0)

        var result: Web3Response<EthereumData>!
        web3.eth.call(call: EthereumCall(to: try EthereumAddress(to.data), data: EthereumData(Array(data))),
                      block: EthereumQuantityTag(tagType: .latest),
                      response: { result = $0; semaphore.signal() })
        semaphore.wait()

        if let error = result.error {
            if let web3Error = error as? Web3Response<EthereumData>.Error {
                switch web3Error {
                case .connectionFailed(let error):
                    if let error = error {
                        throw GSError.detailedError(from: error)
                    } else {
                        throw GSError.ThirdPartyError(reason: "Web3 library connection failed")
                    }
                case .emptyResponse:
                    throw GSError.ThirdPartyError(reason: "Web3 library empty response")
                case .requestFailed(let error):
                    if let error = error {
                        throw GSError.detailedError(from: error)
                    } else {
                        throw GSError.ThirdPartyError(reason: "Web3 library request failed")
                    }
                case .serverError(let error):
                    if let error = error {
                        throw GSError.detailedError(from: error)
                    } else {
                        throw GSError.ThirdPartyError(reason: "Web3 library server error")
                    }
                case .decodingError(let error):
                    if let error = error {
                        throw GSError.detailedError(from: error)
                    } else {
                        throw GSError.ThirdPartyError(reason: "Web3 library decoding error")
                    }
                }
            }
            throw GSError.ThirdPartyError(reason: "Web3 library unknown error")
        } else if let data = result.result {
            return Data(data.bytes)
        } else {
            return Data()
        }
    }

    public func rawCall(payload: String, rpcURL: URL) throws -> String {
        // all requests are proxied to the infura service as is because it is simple to do it now.
        struct RawJSONRPCRequest: HTTPRequest {
            var httpMethod: String { return "POST" }
            var urlPath: String { return "/" }
            var body: Data?
            var url: URL?
            var headers: [String: String] { return ["Content-Type": "application/json"] }
        }
        guard let body = payload.data(using: .utf8) else {
            throw GSError.ThirdPartyError(reason: "Request payload is malformed")
        }
        let request = RawJSONRPCRequest(body: body, url: rpcURL)
        let client = HTTPClient(url: rpcURL, logger: LogService.shared)
        let response = try client.execute(request: request)
        guard let result = String(data: response, encoding: .utf8) else {
            throw GSError.ThirdPartyError(reason: "Response is empty")
        }
        return result
    }
}
