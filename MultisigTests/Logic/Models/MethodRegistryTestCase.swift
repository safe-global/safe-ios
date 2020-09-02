//
//  MethodRegistryTestCase.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 17.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class MethodRegistryTestCase: XCTestCase {

    typealias RawTxData = (label: String, method: String, params: [(name: String, type: String, value: String?)])

    func txData(_ d: RawTxData) -> TransactionData {
        TransactionData(
            method: d.method,
            parameters: d.params.map { TransactionDataParameter(name: $0.name, type: $0.type, value: $0.value, decodedData: nil) }  )
    }

}
