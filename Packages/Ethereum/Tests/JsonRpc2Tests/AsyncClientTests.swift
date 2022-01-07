//
//  AsyncClientTests.swift
//  JsonRpc2Tests
//
//  Created by Dmitry Bespalov on 17.12.21.
//

import XCTest
@testable import JsonRpc2
import TestHelpers

@available(iOS 15.0.0, *)
@available(macOS 12.0.0, *)
class AsyncClientTests: XCTestCase {

    let client = JsonRpc2.AsyncClient(
        transport: JsonRpc2.AsyncHTTPTransport(url: "https://mainnet.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"),
        serializer: JsonRpc2.DefaultSerializer())

    func testSendData() async throws {
        let request =
        """
        {"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}
        """

        print("|>>>", request)

        let input = request.data(using: .utf8)!

        let output = try await client.transport.send(data: input)
        let response = String(data: output, encoding: .utf8)!
        print("|<<o", response)
    }

    func testSendRequest() async throws {
        let request = JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(1))
        try print("|>>>", encode(value: request))

        let response = try await client.send(request: request)

        guard let response = response else {
            XCTFail("nil response")
            return
        }
        guard let result = response.result else {
            try? print("|<<x", encode(value: response.error!))
            XCTFail()
            return
        }

        let number = try result.convert(to: String.self)

        print("|<<o", number)
    }

    func testSendBatchRequest() async throws {
        let request = try JsonRpc2.BatchRequest(requests: [
            JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(1)),
            JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(2))
        ])
        try print("|>>>", encode(value: request))
        let response = try await client.send(request: request)
        switch response {
        case .response(let response):
            try? print("|<<x", encode(value: response))
        case .array(let responses):
            try? print("|<<o", encode(value: responses))
        case .none:
            print("|<<x", "''")
        }
    }
}
