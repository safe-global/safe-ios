//
//  KeyPickerController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class KeyPickerController: UITableViewController {
    private enum Section {
        static let address = 0
        static let showMore = 1
    }

    private enum Index {
        static let `default` = 0
        static let showMore = 0
    }

    private enum ListState {
        case collapsed, expanded
    }

    private var viewModel: SelectOwnerAddressViewModel!
    private var listState = ListState.collapsed
    private var addresses: [Address] {
        switch listState {
        case .collapsed:
            return viewModel.addresses.isEmpty ? [] : Array(viewModel.addresses[0..<1])
        case .expanded:
            return viewModel.addresses
        }
    }

    private lazy var importButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Import",
            style: .done,
            target: self,
            action: #selector(didTapImport))
        return button
    }()

    convenience init(node: HDNode) {
        self.init()
        viewModel = SelectOwnerAddressViewModel(rootNode: node)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(DefaultKeyTableViewCell.self)
        tableView.registerCell(DerivedKeyTableViewCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        navigationItem.title = "Import Owner Key"
        navigationItem.rightBarButtonItem = importButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerSelectAccount)
    }

    @objc func didTapImport() {
        guard viewModel.importWallet() else { return }
        if App.shared.auth.isPasscodeSet || AppSettings.passcodeWasSetAtLeastOnce {
            App.shared.snackbar.show(message: "Owner key successfully imported")
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            let vc = CreatePasscodeViewController()
            vc.navigationItem.hidesBackButton = true
            show(vc, sender: self)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.address:
            return addresses.count
        case Section.showMore:
            return viewModel.canLoadMoreAddresses ? 1 : 0
        default:
            preconditionFailure()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {

        case Section.address:
            let address = addresses[indexPath.row]

            switch indexPath.row {

            case Index.default:
                let cell = tableView.dequeueCell(DefaultKeyTableViewCell.self, for: indexPath)
                cell.setHeader("Default")
                cell.setLeft("#1")
                cell.setAddress(address)
                cell.setSelected(isSelected(indexPath))

                switch listState {
                case .collapsed:
                    cell.setDetail(nil)
                    cell.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
                case .expanded:
                    cell.setDetail("Derived keys are generated from your seed phrase. Select a key you would like to import.")
                    cell.separatorInset = .zero
                }
                return cell

            default:
                let cell = tableView.dequeueCell(DerivedKeyTableViewCell.self, for: indexPath)
                cell.setLeft("#\(indexPath.row + 1)")
                cell.setAddress(address)
                cell.setSelected(isSelected(indexPath))
                return cell
            }

        case Section.showMore:
            let cell = tableView.dequeueCell(ButtonTableViewCell.self)
            cell.height = listState == .collapsed ? 44 : 76
            let label = listState == .collapsed ?
                "Show more derived keys" :
                "Show more"
            cell.setText(label) { [unowned self] in
                self.showMore()
            }
            return cell

        default:
            preconditionFailure()
        }
    }

    private func isSelected(_ indexPath: IndexPath) -> Bool {
        viewModel.selectedIndex == indexPath.row
    }

    private func showMore() {
        var updatedPaths: [IndexPath] = []
        var inserted: [IndexPath] = []
        var deleted: [IndexPath] = []

        if listState == .collapsed {
            listState = .expanded
            updatedPaths = [
                IndexPath(row: Index.default, section: Section.address),
                IndexPath(row: Index.showMore, section: Section.showMore)
            ]

            // we already have 1 address as a default one
            inserted = (1..<viewModel.pageSize).map { IndexPath(row: $0, section: 0) }
        } else {
            inserted = (addresses.count..<(addresses.count + viewModel.pageSize))
                .map { IndexPath(row: $0, section: 0) }

            viewModel.generateAddressesPage()

            if !viewModel.canLoadMoreAddresses {
                deleted = [IndexPath(row: Index.showMore, section: Section.showMore)]
            }
        }

        tableView.beginUpdates()
        do {
            tableView.deleteRows(at: deleted, with: .automatic)
            tableView.reloadRows(at: updatedPaths, with: .automatic)
            tableView.insertRows(at: inserted, with: .bottom)
        }
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == Section.address, indexPath.row != viewModel.selectedIndex else { return }

        let updatedPaths = [indexPath, IndexPath(row: viewModel.selectedIndex, section: 0)]

        viewModel.selectedIndex = indexPath.row

        tableView.beginUpdates()
        do {
            tableView.reloadRows(at: updatedPaths, with: .automatic)
        }
        tableView.endUpdates()
    }
}
