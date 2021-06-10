//
//  BannerTableViewCellTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 10.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Multisig

class BannerTableViewCellTests: XCTestCase {

    func testWhenNotConfiguredThenEmptyUI() {
        let vc = CellTestViewController<BannerTableViewCell>()
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenEmptyValuesThenEmptyUI() {
        let vc = CellTestViewController<BannerTableViewCell>() { cell in
            cell.setHeader(nil)
            cell.setBody(nil)
            cell.setButton("")
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenLongStringsThenEllipsized() {
        let vc = CellTestViewController<BannerTableViewCell>() { cell in
            cell.setHeader("Banner hader with text that is long. Banner hader with text that is long.")
            cell.setBody("Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long. Body banner text that is long.")
            cell.setButton("Button title that is long. Button title that is long. Button title that is long. Button title that is long.")
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenRealisticValuesThenOk() {
        let vc = CellTestViewController<BannerTableViewCell>() { cell in
            cell.setHeader(BalancesViewController.ImportKeyBanner.Strings.header)
            cell.setBody(BalancesViewController.ImportKeyBanner.Strings.body)
            cell.setButton(BalancesViewController.ImportKeyBanner.Strings.button)
        }
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
}
