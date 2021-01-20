//
//  KeyPickerController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class KeyPickerController: UITableViewController {
    var addresses: [Address] = Array(mockData[0..<1])

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

    private var listState = ListState.collapsed
    private var selection: Set<Int> = [0]
    private lazy var importButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Import",
            style: .done,
            target: self,
            action: #selector(didTapImport))
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(DefafultKeyTableViewCell.self)
        tableView.registerCell(DerivedKeyTableViewCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 46
        navigationItem.title = "Import Owner Key"
        navigationItem.rightBarButtonItem = importButton
    }

    @objc func didTapImport() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == Section.address ? addresses.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.address:
            let address = addresses[indexPath.row]
            switch indexPath.row {
            case Index.default:
                let cell = tableView.dequeueCell(DefafultKeyTableViewCell.self, for: indexPath)
                cell.setHeader("Default")
                cell.setLeft("#1")
                cell.setAddress(address)
                let detail = listState == .collapsed ? nil : "Derived keys are generated from your seed phrase. Select a key you would like to import."
                cell.setDetail(detail)
                cell.setSelected(selection.contains(indexPath.row))
                cell.separatorInset = UIEdgeInsets(top: 0, left: listState == .collapsed ? CGFloat.greatestFiniteMagnitude : 0, bottom: 0, right: 0)
                return cell
            default:
                let cell = tableView.dequeueCell(DerivedKeyTableViewCell.self, for: indexPath)
                cell.setLeft("#\(indexPath.row + 1)")
                cell.setAddress(address)
                cell.setSelected(selection.contains(indexPath.row))
                return cell
            }
        case Section.showMore:
            let cell = tableView.dequeueCell(ButtonTableViewCell.self)
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

    private func showMore() {
        var updatedPaths: [IndexPath] = []

        if listState == .collapsed {
            listState = .expanded
            updatedPaths = [
                IndexPath(row: Index.default, section: Section.address),
                IndexPath(row: Index.showMore, section: Section.showMore)
            ]
        }

        let inserted = (0..<Self.mockData.count).map { IndexPath(row: addresses.count + $0, section: Section.address) }
        addresses.append(contentsOf: Self.mockData)

        tableView.beginUpdates()
        do {
            tableView.reloadRows(at: updatedPaths, with: .automatic)
            tableView.insertRows(at: inserted, with: .bottom)
        }
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == Section.address else { return }
        let updatedPaths = [indexPath] + selection.map { IndexPath(row: $0, section: 0) }
        selection = [indexPath.row]

        tableView.beginUpdates()
        do {
            tableView.reloadRows(at: updatedPaths, with: .automatic)
        }
        tableView.endUpdates()
    }
}

extension KeyPickerController {
    static let mockData: [Address] = [
        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        "0xbe0eb53f46cd790cd13851d5eff43d12404d33e8",
        "0x00000000219ab540356cbb839cbe05303d7705fa",
        "0xc61b9bb3a7a0767e3179713f3a5c7a9aedce193c",
        "0xdc76cd25977e0a5ae17155770273ad58648900d3",
        "0x53d284357ec70ce289d6d64134dfac8e511c8a3d",
        "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5",
        "0x73bceb1cd57c711feac4224d062b0f6ff338501e",
        "0x07ee55aa48bb72dcc6e9d78256648910de513eca",
        "0x61edcdf5bb737adffe5043706e7c5bb1f1a56eea",
        "0x229b5c097f9b35009ca1321ad2034d4b3d5070f6",
        "0x1b3cb81e51011b549d78bf720b0d924ac763a7c2",
        "0xe853c56864a2ebe4576a807d26fdc4a0ada51919",
        "0x2bf792ffe8803585f74e06907900c2dc2c29adcb",
        "0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae",
        "0xe92d1a43df510f82c66382592a047d288f85226f",
        "0x3dfd23a6c5e8bbcfc9581d2e864a68feb6a076d3",
        "0x267be1c1d684f78cb4f6a176c4911b741e4ffdc0",
        "0x558553d54183a8542f7832742e7b4ba9c33aa1e6",
        "0xab5801a7d398351b8be11c439e05c5b3259aec9b",
        "0x66f820a414680b5bcda5eeca5dea238543f42054",
        "0xca8fa8f0b631ecdb18cda619c4fc9d197c8affca",
        "0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be",
        "0xf977814e90da44bfa03b6295a0616a897441acec",
        "0x742d35cc6634c0532925a3b844bc454e4438f44e",
    ]
}
