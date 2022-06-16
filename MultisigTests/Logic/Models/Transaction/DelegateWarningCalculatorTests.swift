//
// Created by Dirk Jäckel on 08.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import Version

typealias TxData = SCGModels.TxData

class DelegateWarningCalculatorTests: XCTestCase {
    var decoder: JSONDecoder = JSONDecoder()

    override func setUp() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
    }

    override func tearDown() {
    }

    // MultiSend TXs
    func testTopLevelWarning() throws {
        // https://safe-client.gnosis.io/v1/chains/4/transactions/multisig_0x73a7AA145338587f7aB7f63c06d187C85dF4727e_0xba28109747222d6cfb7f0fb75f03d49957e343674bc116162b038e244dbcc6d6
        let txData = try loadAndParseFile(fileName: "DelegateWarningTopLevel")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendInnerWarning() throws {
        let txData = try loadAndParseFile(fileName: "DelegateWarningMultiSend")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendInnerWarningAndNotTopLevel() throws {
        let txData = try loadAndParseFile(fileName: "NoDelegateOperationButDelegateFlag")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendOperationIsDelegateButToAddressIsKnown() throws {
        let txData = try loadAndParseFile(fileName: "NoDelegateWarningBecauseMultiSendAddressIsKnown")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Multisend operation is delegate but to: address is known
        XCTAssertFalse(result)
    }

    func testMultiSendOperationNoDelegateNoFlag() throws {
        let txData = try loadAndParseFile(fileName: "NoDelegateWarningBecauseNoDelegateOperation")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // No delegate operation to be found. And no trustedDelegateCallTarget
        XCTAssertFalse(result)
    }

    func testOuterTxHasWarning() throws {
        let txData = try loadAndParseFile(fileName: "NoDelegateOperationButDelegateFlag")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // No delegate operation to be found. But trustedDelegateCallTarget -> Warning
        XCTAssertTrue(result)
    }

    func testDataDecodedWithFlagAndMultiSend() throws {
        let txData = try loadAndParseFile(fileName: "DelegateWarningMultiSend")

        let result = DelegateWarningCalculator.isUntrusted(dataDecoded: txData.dataDecoded, addressInfoIndex: txData.addressInfoIndex)

        // Delegate operation to be found. With unknown Address -> Warning
        XCTAssertTrue(result)
    }

    func testDataDecodedWithoutFlagAndMultiSend() throws {
        let txData = try loadAndParseFile(fileName: "DelegateWarningNotTopLevel")

        let result = DelegateWarningCalculator.isUntrusted(dataDecoded: txData.dataDecoded, addressInfoIndex: txData.addressInfoIndex)

        // Delegate operation to be found. With unknown Address -> Warning
        XCTAssertTrue(result)
    }

    // Transfers
    func testTransferWithDelegateWarning() throws {
        let txData = try loadAndParseFile(fileName: "TransferWithDelegateWarning")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Delegate flag set to false -> Warning
        XCTAssertTrue(result)
    }

    func testTransferNoDelegateWarning() throws {
        let txData = try loadAndParseFile(fileName: "TransferNoDelegateWarning")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Delegate flag set not set -> No Warning
        XCTAssertFalse(result)
    }

    func testTransferNoWarningButDelegate() throws {
        let txData = try loadAndParseFile(fileName: "TransferNoWarningButDelegate")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Delegate flag not set. But Delegate with unknown Address -> Warning
        XCTAssertTrue(result)
    }

    func testTransferNoWarningButDelegateWithName() throws {
        let txData = try loadAndParseFile(fileName: "TransferNoWarningButDelegateWithName")

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Delegate flag not set. But Delegate with known Address -> No Warning
        XCTAssertFalse(result)
    }

    // Helper
    private func loadAndParseFile(fileName: String) throws -> TxData {
        let data = jsonData(fileName)
        let decodedData = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
        return decodedData.txData!
    }

    private func jsonData(_ name: String) -> Data {
        try! Data(contentsOf: Bundle(for: Self.self).url(forResource: name, withExtension: "json")!)
    }
}
