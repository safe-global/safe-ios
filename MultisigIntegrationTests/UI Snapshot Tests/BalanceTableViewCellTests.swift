//
//  BalanceTableViewCellTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 09.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Multisig

class BalanceTableViewCellTests: XCTestCase {
    func testWhenRealisitcValuesThenOk() {
        let vc = CellTestViewController<BalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText("ETH")
            cell.setDetailText("0,005")
            cell.setSubDetailText("155,84 USD")
            cell.setImage(UIImage(named: "ico-ether")!)
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenNotConfiguredThenEmptyUI() {
        let vc = CellTestViewController<BalanceTableViewCell>(estimatedHeight: 60)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenEmptyValuesThenEmptyUI() {
        let vc = CellTestViewController<BalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText("")
            cell.setDetailText("")
            cell.setSubDetailText("")
            cell.setImage(UIImage())
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenLongStringsThenEllipsized() {
        let vc = CellTestViewController<BalanceTableViewCell>(estimatedHeight: 60) { cell in
            cell.setMainText(String(repeating: "ETH repeating ", count: 15))
            cell.setDetailText(String(repeating: "0,005", count: 15))
            cell.setSubDetailText(String(repeating: "155,84 USD", count: 15))
            cell.setImage(UIImage(named: "ico-ether")!)
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
}
