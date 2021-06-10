//
//  TotalBalanceTableViewCellTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 10.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Multisig

class TotalBalanceTableViewCellTests: XCTestCase {

    func testWhenNotConfiguredThenEmptyUI() {
        let vc = CellTestViewController<TotalBalanceTableViewCell>(estimatedHeight: 60)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenEmptyValuesThenEmptyUI() {
        let vc = CellTestViewController<TotalBalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText("")
            cell.setDetailText("")
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenLongStringsThenEllipsized() {
        let vc = CellTestViewController<TotalBalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText("Text that is very long. Text that is very long. Text that is very long. ")
            cell.setDetailText("Detail text that is very long. Detail text that is very long. Detail text that is very long.")
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenRealisticValuesThenOk() {
        let vc = CellTestViewController<TotalBalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText("Total")
            cell.setDetailText("19,415.94 USD")
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
}
