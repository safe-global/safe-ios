//
//  BalancesTableViewControllerTests.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 17.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Multisig

class BalancesTableViewControllerTests: XCTestCase {

    /// Reusable test data to show some entries on the screen
    let balanceSummary = BalancesTableViewController.Balances.Summary(
        total: .init("7 000 000 EUR"),
        entries:
            .init(repeating:
                    .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                          name: "GNO",
                          tokenAmount: "1",
                          quoteAmount: "1 000 000 EUR"),
                  count: 7
            )
    )

    override func setUpWithError() throws {
//        isRecording = true
    }

    func testWhenEmptyThenOk() {
        let vc = BalancesTableViewController()
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhen01EntryThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: nil,
            summary: .init(
                total: .init("1 000 000 EUR"),
                entries: [
                    .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                          name: "GNO",
                          tokenAmount: "1",
                          quoteAmount: "1 000 000 EUR")
                ]
            )
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhen03EntriesThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: nil,
            summary: .init(
                total: .init("3 000 000 EUR"),
                entries: [
                    // *nativeCoin*
                    .init(image: LocalImageData(image: UIImage(named: "ico-ether")),
                          name: "ETH",
                          tokenAmount: "1",
                          quoteAmount: "1 000 000 EUR"),
                    .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                          name: "GNO",
                          tokenAmount: "1",
                          quoteAmount: "1 000 000 EUR"),
                    .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                          name: "OWL",
                          tokenAmount: "1",
                          quoteAmount: "1 000 000 EUR")
                ]
            )
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX, traits: UITraitCollection(userInterfaceStyle: .dark)))
    }

    func testWhen90EntriesThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: nil,
            summary: .init(
                total: .init("90 000 000 EUR"),
                entries:
                    .init(repeating:
                            .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                                  name: "GNO",
                                  tokenAmount: "1",
                                  quoteAmount: "1 000 000 EUR"),
                          count: 90
                    )
            )
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(size: CGSize(width: 375, height: 6_000)))
    }

    func testWhenImportKeyBannerThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: BalancesTableViewController.Balances.ImportKeyBannerPlaceholder(),
            summary: balanceSummary
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX, traits: UITraitCollection(userInterfaceStyle: .dark)))
    }

    func testWhenPasscodeBannerThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: BalancesTableViewController.Balances.PasscodeBannerPlaceholder(),
            summary: balanceSummary
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX, traits: UITraitCollection(userInterfaceStyle: .dark)))
    }

    func testWhenRefreshingThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: true,
            banner: nil,
            summary: balanceSummary
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenStopsRefreshingThenOk() {
        let vc = BalancesTableViewController()
        var data = BalancesTableViewController.Balances(
            isRefreshing: true,
            banner: nil,
            summary: balanceSummary
        )
        vc.reload(data)

        data.isRefreshing = false
        vc.reload(data)

        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }

    func testWhenLongStringsThenOk() {
        let vc = BalancesTableViewController()
        let data = BalancesTableViewController.Balances(
            isRefreshing: false,
            banner: nil,
            summary: .init(
                total: .init("1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 EUR"),
                entries: [
                    .init(image: LocalImageData(image: UIImage(named: "ico-token-placeholder")),
                          name: "Gnosis DAO Token With Long Descriptive Name That Does Not Fit The Width",
                          tokenAmount: "1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000",
                          quoteAmount: "1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 EUR")
                ]
            )
        )
        vc.reload(data)
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
    }
}
