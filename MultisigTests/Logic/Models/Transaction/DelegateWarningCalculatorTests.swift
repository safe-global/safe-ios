//
// Created by Dirk Jäckel on 08.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import Version

class DelegateWarningCalculatorTests: XCTestCase {

    private func jsonData(_ name: String) -> Data {
        try! Data(contentsOf: Bundle(for: Self.self).url(forResource: name, withExtension: "json")!)
    }

    func testTopLevelWarning() throws {
        // https://safe-client.gnosis.io/v1/chains/4/transactions/multisig_0x73a7AA145338587f7aB7f63c06d187C85dF4727e_0xba28109747222d6cfb7f0fb75f03d49957e343674bc116162b038e244dbcc6d6
        let data = jsonData("DelegateWarningTopLevel")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decodedData = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
        let txData: SCGModels.TxData = decodedData.txData!

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendInnerWarning() throws {
        // https://safe-client.gnosis.io/v1/chains/4/transactions/multisig_0x73a7AA145338587f7aB7f63c06d187C85dF4727e_0xba28109747222d6cfb7f0fb75f03d49957e343674bc116162b038e244dbcc6d6
        let data = jsonData("DelegateWarningMultiSend")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decodedData = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
        let txData: SCGModels.TxData = decodedData.txData!

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendInnerWarningAndNotTopLevel() throws {
        // https://safe-client.gnosis.io/v1/chains/4/transactions/multisig_0x73a7AA145338587f7aB7f63c06d187C85dF4727e_0xba28109747222d6cfb7f0fb75f03d49957e343674bc116162b038e244dbcc6d6
        let data = jsonData("DelegateWarningNotTopLevel")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decodedData = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
        let txData: SCGModels.TxData = decodedData.txData!

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        XCTAssertTrue(result)
    }

    func testMultiSendOperationIsDelegateButToAddressIsKnown() throws {
        // https://safe-client.gnosis.io/v1/chains/4/transactions/multisig_0x73a7AA145338587f7aB7f63c06d187C85dF4727e_0xba28109747222d6cfb7f0fb75f03d49957e343674bc116162b038e244dbcc6d6
        let data = jsonData("NoDelegateWarningBecauseMultiSendAddressIsKnown")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decodedData = try decoder.decode(SCGModels.TransactionDetails.self, from: data)
        let txData: SCGModels.TxData = decodedData.txData!

        let result = DelegateWarningCalculator.isUntrusted(txData: txData)

        // Multisend operation is delegate but to address is known
        XCTAssertFalse(result)
    }
}
