//
//  BalancesTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class BalancesTableViewController: UITableViewController {

    private var data: Balances = .empty

    override func viewDidLoad() {
        super.viewDidLoad()

        // configure table view
        tableView.allowsSelection = false
        tableView.backgroundColor = .primaryBackground
        tableView.refreshControl = makeRefreshControl()

        // register cells
        tableView.registerCell(ImportKeyBannerCell.self)
        tableView.registerCell(CreatePasscodeBannerCell.self)
        tableView.registerCell(TotalCell.self)
        tableView.registerCell(BalanceCell.self)

        // auto-sizing
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    private func makeRefreshControl() -> UIRefreshControl {
        let control = UIRefreshControl()
        return control
    }

    /// Updates the UI based on the new data
    /// - Parameter newData: updated screen data
    func reload(_ newData: Balances) {
        data = newData

        tableView.reloadData()

        if data.isRefreshing {
            tableView.refreshControl?.beginRefreshing()
        } else if tableView.refreshControl?.isRefreshing == true {
            tableView.refreshControl?.endRefreshing()
        }
    }

    // MARK: UITableViewDataSource implementation

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = data[indexPath]

        switch cellData {

        case is Balances.ImportKeyBannerPlaceholder:
            return tableView.dequeueCell(ImportKeyBannerCell.self, for: indexPath)

        case is Balances.PasscodeBannerPlaceholder:
            return tableView.dequeueCell(CreatePasscodeBannerCell.self, for: indexPath)

        case let total as Balances.Total:
            let cell = tableView.dequeueCell(TotalCell.self, for: indexPath)
            cell.detailText = total.quoteAmount
            return cell

        case let entry as Balances.Entry:
            let cell = tableView.dequeueCell(BalanceCell.self, for: indexPath)
            cell.mainText = entry.name
            cell.detailText = entry.tokenAmount
            cell.subDetailText = entry.quoteAmount
            cell.image = entry.image
            return cell

        default:
            return UITableViewCell()
        }
    }
}

// MARK: UI Data

extension BalancesTableViewController {
    /// UI data model for the controller
    struct Balances {
        static let empty = Balances()

        /// Whether the refresh indicator is shown or not
        var isRefreshing: Bool = false

        /// If not nil, then a banner will be shown.
        /// Only one banner at a time.
        var banner: BannerPlaceholder?

        /// If not nil, then the entries and total cells will be shown
        var summary: Summary?

        /// Creates cell data from the banner and summary
        var cellData: [BalancesCellData] {
            var items: [BalancesCellData] = []

            if let banner = banner {
                items.append(banner)
            }

            if let summary = summary {
                items.append(summary.total)
                items.append(contentsOf: summary.entries)
            }

            return items
        }

        /// Returns cell data for the row of the indexPath
        subscript(indexPath: IndexPath) -> BalancesCellData {
            cellData[indexPath.row]
        }

        /// Number of items in cell data
        var count: Int {
            cellData.count
        }

        // MARK: Data Types

        /// Base type to describe cell data for the table view.
        /// Use subclasses only (leafs).
        class BalancesCellData {}

        /// Banner base type. Use subclasses only.
        class BannerPlaceholder: BalancesCellData {}

        /// Represents "import key" banner
        class ImportKeyBannerPlaceholder: BannerPlaceholder {}

        /// Represents "create passcode" banner
        class PasscodeBannerPlaceholder: BannerPlaceholder {}

        /// Data for the "total" row
        class Total: BalancesCellData {
            /// Amount in quote currency (fiat)
            var quoteAmount: String

            init(_ value: String) {
                quoteAmount = value
            }
        }

        /// Data for the coin balance rows
        class Entry: BalancesCellData {
            /// Logo of the token
            var image: ImageData
            /// The name of the token
            var name: String
            /// Amount of tokens
            var tokenAmount: String
            /// Value of token amount in quote currency (fiat balance)
            var quoteAmount: String

            /// Creates new Entry
            /// - Parameters:
            ///   - image: token image
            ///   - name: token name or symbol
            ///   - tokenAmount: amount of tokens
            ///   - quoteAmount: value of tokens in quote currency (fiat balance)
            init(image: ImageData, name: String, tokenAmount: String, quoteAmount: String) {
                self.image = image
                self.name = name
                self.tokenAmount = tokenAmount
                self.quoteAmount = quoteAmount
            }
        }

        /// Represents balance summary data
        struct Summary {
            /// Total value in quote currency
            var total: Total
            /// Token amounts
            var entries: [Entry]

            /// Creates balance summary if entries are not empty.
            /// The "total" makes sense only if there are entries to show.
            ///
            /// - Parameters:
            ///   - total: total value in quote currency
            ///   - entries: token amounts. Must not be empty. If empty, then returns nil.
            init?(total: Total, entries: [Entry]) {
                if entries.isEmpty { return nil }
                self.total = total
                self.entries = entries
            }
        }
    }
}
