//
//  JsonRpc2ClientTests.swift
//  JsonRpc2Tests
//
//  Created by Dmitry Bespalov on 16.12.21.
//

import XCTest
@testable import JsonRpc2
import TestHelpers

class JsonRpc2ClientTests: XCTestCase {
    let client = JsonRpc2.Client(
        transport: JsonRpc2.ClientHTTPTransport(url: "https://mainnet.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"),
        serializer: JsonRpc2.DefaultSerializer())

    func testSendData() {
        let exp = expectation(description: "Request")
        do {
            let request =
            """
            {"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}
            """

            print("|>>>", request)

            let data = request.data(using: .utf8)!

            client.transport.send(data: data) { result in
                switch result {
                case .success(let data):
                    let response = String(data: data, encoding: .utf8)!
                    print("|<<o", response)

                case .failure(let error):
                    print("|<<x", error)
                    XCTFail()
                }

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 300, handler: nil)
    }

    func testSendRequest() throws {
        let exp = expectation(description: "Request")
        do {
            let request = JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(1))
            try print("|>>>", encode(value: request))

            client.send(request: request) { response in
                guard let response = response else {
                    XCTFail("nil response")
                    exp.fulfill()
                    return
                }

                if let result = response.result {

                    do {
                        let number = try result.convert(to: String.self)

                        print("|<<o", number)
                    } catch {
                        XCTFail("Failed to decode: \(result) to String")
                    }

                } else {
                    try? print("|<<x", encode(value: response.error!))
                    XCTFail()
                }

                exp.fulfill()
            }

        }
        waitForExpectations(timeout: 300, handler: nil)
    }

    func testSendBatchRequest() throws {
        let exp = expectation(description: "Request")
        do {
            let request = try JsonRpc2.BatchRequest(requests: [
                JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(1)),
                JsonRpc2.Request(jsonrpc: "2.0", method: "eth_blockNumber", params: nil, id: .int(2))
            ])
            try print("|>>>", encode(value: request))
            client.send(request: request) { response in

                switch response {
                case .response(let response):
                    try? print("|<<x", encode(value: response))
                case .array(let responses):
                    try? print("|<<o", encode(value: responses))
                case .none:
                    print("|<<x", "''")
                }

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 300, handler: nil)
    }
}
