//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import XCTest
import Eth
import JsonRpc2
import Solidity

class TransactionTests: XCTestCase {
    let chain = "Ethereum"
    let rpcUri = "https://mainnet.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"
    let address: Sol.Address = "0x53A7e1E613DfEd15C76635D95e8E063e25ff7aE5"

    var client: JsonRpc2.Client!

    override func setUp() {
        super.setUp()
        client = JsonRpc2.Client(
                transport: JsonRpc2.ClientHTTPTransport(url: rpcUri),
                serializer: JsonRpc2.DefaultSerializer())
    }

    func testBalance() {
        let exp = expectation(description: "get balance")
        _ = client.call(Node.eth_getBalance(address: address, block: .blockTag(.pending)) { result in
            defer {
                exp.fulfill()
            }
            do {
                let balance = try result.get()
                XCTAssertEqual(balance, 108720173170985000)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 5)
    }

    func testNonce() {
        let exp = expectation(description: "get tx count")
        _ = client.call(Node.eth_getTransactionCount(address: address, block: .blockTag(.pending)) { result in
            defer { exp.fulfill() }
            do {
                let transactionCount = try result.get()
                XCTAssertEqual(transactionCount, 3)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 5)
    }
    
    func testCode() {
        let address: Sol.Address = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
        let exp = expectation(description: "get tx count")
        _ = client.call(Node.eth_getCode(address: address, block: .blockTag(.pending)) { result in
            defer { exp.fulfill() }
            do {
                let code = try result.get()
                XCTAssertEqual(code.count, 24497)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 5)
    }

    func testAccount() {
        let address: Sol.Address = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
        let exp = expectation(description: "load account with code")
        _ = Node.account(at: address, using: client) { account in
            defer { exp.fulfill() }
            XCTAssertEqual(account.balance, 0)
            XCTAssertEqual(account.nonce, 1)
            XCTAssertEqual(account.code?.count, 24497)
        }
        waitForExpectations(timeout: 5)
    }
}
