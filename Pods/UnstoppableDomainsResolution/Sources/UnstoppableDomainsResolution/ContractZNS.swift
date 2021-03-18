//
//  Contract.swift
//  resolution
//
//  Created by Serg Merenkov on 9/8/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class ContractZNS {
    let address: String
    let providerUrl: String
    let networking: NetworkingLayer

    init(providerUrl: String, address: String, networking: NetworkingLayer) {
        self.address = address
        self.providerUrl = providerUrl
        self.networking = networking
    }

    func fetchSubState(field: String, keys: [String]) throws -> Any {

        let body: JsonRpcPayload = JsonRpcPayload(
            jsonrpc: "2.0",
            id: "1",
            method: "GetSmartContractSubState",
            params: [
                ParamElement.string(self.address),
                ParamElement.string(field),
                ParamElement.array(keys.map { ParamElement.string($0) })
            ]
        )
        let response = try postRequest(body)!

        guard case let ParamElement.dictionary(dict) = response,
            let results = self.reduce(dict: dict)[field] as? [String: Any] else {
             print("Invalid response, can't process")
             return response
        }

        return results
    }

    private func postRequest(_ body: JsonRpcPayload) throws -> Any? {
        let postRequest = APIRequest(providerUrl, networking: networking)
        var resp: JsonRpcResponse?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        try postRequest.post(body, completion: {result in
            switch result {
            case .success(let response):
                resp = response[0]
            case .failure(let error):
                err = error
            }
            semaphore.signal()
        })
        semaphore.wait()
        guard err == nil else {
            throw err!
        }
        return resp?.result
    }

    // MARK: - PRIVATE Helper functions

    private func reduce(dict: [String: ParamElement]) -> [String: Any] {
        return dict.reduce(into: [String: Any]()) { dict, pair in
            let (key, value) = pair

            switch value {
            case .paramClass(let elem):
                dict[key] = elem
            case .string(let elem):
                dict[key] = elem
            case .array(let array):
                dict[key] = self.map(array: array)
            case .dictionary(let dictionary):
                dict[key] = self.reduce(dict: dictionary)
            }
        }
    }

    private func map(array: [ParamElement]) -> [Any] {
        return array.map { (value) -> Any in
            switch value {
            case .paramClass(let elem):
                return elem
            case .string(let elem):
                return elem
            case .array(let array):
                return self.map(array: array)
            case .dictionary(let dictionary):
                return self.reduce(dict: dictionary)
            }
        }
    }
}
