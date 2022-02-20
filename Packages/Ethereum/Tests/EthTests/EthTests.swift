//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import XCTest
import Eth
import JsonRpc2
import Solidity
import Json

class TransactionTests: XCTestCase {
    let chain = "Ethereum"
    let rpcUri = "https://mainnet.infura.io/v3/fda31d5c85564ae09c97b1b970e7eb33"
    let address: Sol.Address = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"

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
                XCTAssertEqual(balance, 0)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testNonce() {
        let exp = expectation(description: "get tx count")
        _ = client.call(Node.eth_getTransactionCount(address: address, block: .blockTag(.pending)) { result in
            defer { exp.fulfill() }
            do {
                let transactionCount = try result.get()
                XCTAssertEqual(transactionCount, 1)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }
    
    func testCode() {
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
        waitForExpectations(timeout: 30)
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
        waitForExpectations(timeout: 30)
    }

    func testTransactionLegacy() {
        let hash: Node.Hash = "0xa65ffc6bcf0fdce0ac70803a446fa50d7b958589c49a65237316df5a21c9c486"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionByHash(hash: hash) { result in
            defer { exp.fulfill() }
            do {
                guard let transaction = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                guard let legacy = transaction as? Node.TransactionLegacy else {
                    XCTFail("Unexpected transaction type: \(transaction)")
                    return
                }

                XCTAssertEqual(legacy.feeLegacy.gasPrice, 104500000000)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testTransaction1559() {
        let hash: Node.Hash = "0xbbde8eb76e55c61807493653453c71b82dfec03c3204e80fca47622741da3607"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionByHash(hash: hash) { result in
            defer { exp.fulfill() }
            do {
                guard let transaction = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                guard let tx1559 = transaction as? Node.Transaction1559 else {
                    XCTFail("Unexpected transaction type: \(transaction)")
                    return
                }
                XCTAssertEqual(tx1559.fee1559.maxPriorityFeePerGas, 1_000_000_000)
                XCTAssertEqual(tx1559.fee1559.maxFeePerGas, 162_756_143_860)
                XCTAssertEqual(tx1559.signature2930.yParity, 0)
                XCTAssertEqual(tx1559.signature2930.r, "50078468011924057578168471388802460079889621452335610668635439536646526886298")
                XCTAssertEqual(tx1559.chainId, 1)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testTransaction1559ByBlockNumberAndIndex() {
        let hash: Node.Hash = "0xbbde8eb76e55c61807493653453c71b82dfec03c3204e80fca47622741da3607"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionByBlockNumberAndIndex(block: .number(0xd7fcdd), transactionIndex: 0xd1) { result in
            defer { exp.fulfill() }
            do {
                guard let transaction = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                guard let tx1559 = transaction as? Node.Transaction1559 else {
                    XCTFail("Unexpected transaction type: \(transaction)")
                    return
                }
                XCTAssertEqual(tx1559.hash, hash)
                XCTAssertEqual(tx1559.fee1559.maxPriorityFeePerGas, 1_000_000_000)
                XCTAssertEqual(tx1559.fee1559.maxFeePerGas, 162_756_143_860)
                XCTAssertEqual(tx1559.signature2930.yParity, 0)
                XCTAssertEqual(tx1559.signature2930.r, "50078468011924057578168471388802460079889621452335610668635439536646526886298")
                XCTAssertEqual(tx1559.chainId, 1)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testTransaction1559ByBlockHashAndIndex() {
        let blockHash: Node.Hash = "0x9abb9adff36c18c850a8bcd92fb90a06e848efc4bf7e362cd1d3c760cc464d6f"
        let transactionHash: Node.Hash = "0xbbde8eb76e55c61807493653453c71b82dfec03c3204e80fca47622741da3607"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionByBlockHashAndIndex(blockHash: blockHash, transactionIndex: 0xd1) { result in
            defer { exp.fulfill() }
            do {
                guard let transaction = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                guard let tx1559 = transaction as? Node.Transaction1559 else {
                    XCTFail("Unexpected transaction type: \(transaction)")
                    return
                }
                XCTAssertEqual(tx1559.hash, transactionHash)
                XCTAssertEqual(tx1559.fee1559.maxPriorityFeePerGas, 1_000_000_000)
                XCTAssertEqual(tx1559.fee1559.maxFeePerGas, 162_756_143_860)
                XCTAssertEqual(tx1559.signature2930.yParity, 0)
                XCTAssertEqual(tx1559.signature2930.r, "50078468011924057578168471388802460079889621452335610668635439536646526886298")
                XCTAssertEqual(tx1559.chainId, 1)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testTransaction2930() {
        let hash: Node.Hash = "0xad07c974c9235ac6078a2153cf90b826a52555c7fb5100400bf0cec1699ed0ad"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionByHash(hash: hash) { result in
            defer { exp.fulfill() }
            do {
                guard let transaction = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                guard let tx2930 = transaction as? Node.Transaction2930 else {
                    XCTFail("Unexpected transaction type: \(transaction)")
                    return
                }
                XCTAssertEqual(tx2930.accessList.first?.address, "0xe776df26ac31c46a302f495c61b1fab1198c582a")
                XCTAssertEqual(tx2930.accessList.first?.storageKeys.first, "0x0000000000000000000000000000000000000000000000000000000000000000")
                XCTAssertEqual(tx2930.signature2930.r, "109707341365307446084711329270212590736837184815573345704346419718882231771312")
                XCTAssertEqual(tx2930.feeLegacy.gasPrice, 185_000_000_000)
                XCTAssertEqual(tx2930.chainId, 1)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testEstimateGas() {
        let exp = expectation(description: "estimate gas")
        let message = Node.MessageCall(
                from: "0x6680900ed71fc42851d0dcfd2768bb3bec657692",
                to: "0x9b8e9d523d1d6bc8eb209301c82c7d64d10b219e",
                data: Data(hex: "0x095ea7b30000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d0000000000000000000000000000000000000000000000000de0b6b3a7640000")
        )
        _ = client.call(Node.eth_estimateGas(message: message, block: .blockTag(.pending)) { (response: Result<Sol.UInt256, Error>) in
            defer { exp.fulfill() }
            do {
                let result = try response.get()
                XCTAssertEqual(result, 29237)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testCall() {
        let exp = expectation(description: "estimate gas")
        let message = Node.MessageCall(
                from: "0x6680900ed71fc42851d0dcfd2768bb3bec657692",
                to: "0x9b8e9d523d1d6bc8eb209301c82c7d64d10b219e",
                data: Data(hex: "0x095ea7b30000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d0000000000000000000000000000000000000000000000000de0b6b3a7640000")
        )
        _ = client.call(Node.eth_call(message: message, block: .blockTag(.pending)) { (response: Result<Data, Error>) in
            defer { exp.fulfill() }
            do {
                let result = try response.get()
                let bool = try Sol.Bool(result).storage
                XCTAssertTrue(bool)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)
    }

    func testReceipt() {
        let transactionHash: Node.Hash = "0xbbde8eb76e55c61807493653453c71b82dfec03c3204e80fca47622741da3607"
        let exp = expectation(description: "get transaction")
        _ = client.call(Node.eth_getTransactionReceipt(hash: transactionHash) { result in
            defer { exp.fulfill() }
            do {
                guard let receipt = try result.get() else {
                    XCTFail("Not found")
                    return
                }
                XCTAssertEqual(receipt.status, 1)
                XCTAssertEqual(receipt.from, "0x6680900ed71fc42851d0dcfd2768bb3bec657692")
                XCTAssertEqual(receipt.to, "0x9b8e9d523d1d6bc8eb209301c82c7d64d10b219e")
                XCTAssertNil(receipt.contractAddress)
                XCTAssertEqual(receipt.logs, [
                    Node.Log(address: "0x9b8e9d523d1d6bc8eb209301c82c7d64d10b219e",
                             data: Data(hex: "0x0000000000000000000000000000000000000000000000000de0b6b3a7640000"),
                             topics: [
                                "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
                                "0x0000000000000000000000006680900ed71fc42851d0dcfd2768bb3bec657692",
                                "0x0000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d"].map(Data.init(hex:)).map(Sol.Bytes32.init(storage:)),
                             removed: false,
                             logIndex: 0x158,
                             blockPath: Node.BlockPath(
                                blockHash: "0x9abb9adff36c18c850a8bcd92fb90a06e848efc4bf7e362cd1d3c760cc464d6f",
                                blockNumber: 0xd7fcdd,
                                transactionIndex: 0xd1),
                             transactionHash: "0xbbde8eb76e55c61807493653453c71b82dfec03c3204e80fca47622741da3607")
                ])
                XCTAssertEqual(receipt.logsBloom, Data(hex: "0x00000000000000000000000000000000000000000000000000010000000000000000000004000000000000000000002000000000000000000000000000200000000000000000000000000000000200000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000020000000000000000000004000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000010000000000000000000000000000000000000000000000000000000000000"))
                XCTAssertEqual(receipt.blockPath.transactionIndex, 209)
                XCTAssertEqual(receipt.blockPath.blockHash, "0x9abb9adff36c18c850a8bcd92fb90a06e848efc4bf7e362cd1d3c760cc464d6f")
                XCTAssertEqual(receipt.blockPath.blockNumber, 14154973)
            } catch {
                XCTFail("Error: \(error)")
            }
        })
        waitForExpectations(timeout: 30)

    }
}
