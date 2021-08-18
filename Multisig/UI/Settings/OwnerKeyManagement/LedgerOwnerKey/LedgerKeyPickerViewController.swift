//
//  LedgerKeyPickerViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyPickerViewController: SegmentViewController {
    convenience init() {
        self.init(namedClass: nil)
        segmentItems = [
            SegmentBarItem(image: nil, title: "Ledger Live"),
            SegmentBarItem(image: nil, title: "Ledger")
        ]
        viewControllers = [
            LedgerKeyPickerContentViewController(type: .ledgerLive),
            LedgerKeyPickerContentViewController(type: .ledger)
        ]
        selectedIndex = 0
    }
}

fileprivate class LedgerKeyPickerViewModel {
    var keys = [KeyAddressInfo]()
    var maxItemCount = 100
    var pageSize = 10
    var isLoading = true
    var selectedIndex = -1

    var canLoadMoreAddresses: Bool {
        keys.count < maxItemCount
    }

    struct KeyAddressInfo {
        var index: Int
        var address: Address
        var name: String?
        var exists: Bool { name != nil }
    }

    func generateNextPage(completion: () -> Void) {
        isLoading = true

        // this will be async
        do {
            let indexes = (keys.count..<keys.count + pageSize)
            let addresses = indexes.map { _ in Address.zero }
            let infoByAddress = try Dictionary(grouping: KeyInfo.keys(addresses: addresses), by: \.address)

            let nextPage = indexes.enumerated().map { (i, addressIndex) -> KeyAddressInfo in
                let address = addresses[i]
                return KeyAddressInfo(index: addressIndex, address: address, name: infoByAddress[address]?.first?.name)
            }

            keys += nextPage
        } catch {
            LogService.shared.error("Failed to generate addresses: \(error)")
            App.shared.snackbar.show(
                error: GSError.UnknownAppError(description: "Could not generate addresses",
                                               reason: "Unexpected error occurred.",
                                               howToFix: "Please try again later")
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
            self?.isLoading = false
        }
    }
}

fileprivate class LedgerKeyPickerContentViewController: UITableViewController {
    private var model: LedgerKeyPickerViewModel!

    enum LedgerKeyType {
        case ledgerLive
        case ledger
    }

    convenience init(type: LedgerKeyType) {
        self.init()
        switch type {
        case .ledgerLive: model = LedgerKeyPickerViewModel()
        case .ledger: model = LedgerKeyPickerViewModel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Connect Ledger Key"

        tableView.registerCell(DerivedKeyTableViewCell.self)
        tableView.registerCell(LoadingValueCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        // TODO: handle errors when can't load a batch of keys
        model.generateNextPage { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.keys.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if model.isLoading && indexPath.row == model.keys.count  {
            return tableView.dequeueCell(LoadingValueCell.self)
        } else if indexPath.row == model.keys.count {
            let cell = tableView.dequeueCell(ButtonTableViewCell.self)
            let text = model.keys.count == 0 ? "Retry" : "Load more"
            cell.setText(text) { [weak self] in
                self?.model.generateNextPage {
                    self?.tableView.reloadData()
                }
            }
            return tableView.dequeueCell(ButtonTableViewCell.self)
        }

        let key = model.keys[indexPath.row]
        let cell = tableView.dequeueCell(DerivedKeyTableViewCell.self, for: indexPath)
        cell.setLeft("#\(key.index + 1)")
        cell.setAddress(key.address)
        cell.setSelected(isSelected(indexPath))
        cell.setEnabled(!key.exists)

        return cell
    }

    private func isSelected(_ indexPath: IndexPath) -> Bool {
        model.selectedIndex == indexPath.row
    }
}
