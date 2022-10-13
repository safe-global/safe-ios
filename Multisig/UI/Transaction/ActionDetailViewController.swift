//
//  ActionDetailViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter


class ActionDetailViewController: UITableViewController {
    typealias MultiSendTx = SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx
    typealias DataDecoded = SCGModels.DataDecoded
    typealias AddressInfoIndex = SCGModels.AddressInfoIndex

    private var multiSendTx: MultiSendTx?
    private var addressInfoIndex: AddressInfoIndex?
    private var chain: Chain!
    private var dataDecoded: DataDecoded?
    private var data: DataString?
    private var placeholderTitle: String?

    private static let indentWidth: CGFloat = 20.0

    private var txBuilder: TransactionDetailCellBuilder!

    /// Container for all cells in the table
    private var cells = [UITableViewCell]()

    convenience init(decoded: DataDecoded,
                     addressInfoIndex: AddressInfoIndex?,
                     chain: Chain,
                     data: DataString? = nil) {
        self.init()
        self.dataDecoded = decoded
        self.addressInfoIndex = addressInfoIndex
        self.chain = chain
        self.data = data
    }

    convenience init(tx: MultiSendTx,
                     addressInfoIndex: AddressInfoIndex?,
                     chain: Chain,
                     placeholderTitle: String?) {
        self.init()
        multiSendTx = tx
        self.addressInfoIndex = addressInfoIndex
        self.chain = chain
        dataDecoded = tx.dataDecoded
        data = tx.data
        self.placeholderTitle = placeholderTitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        txBuilder = TransactionDetailCellBuilder(vc: self, tableView: tableView, chain: chain)
        tableView.registerCell(ActionDetailTextCell.self)
        tableView.registerCell(ActionDetailExpandableCell.self)
        tableView.registerCell(ActionDetailAddressCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.backgroundColor = .backgroundSecondary
        reloadData()

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .addressbookChanged,
                             .selectedSafeChanged,
                             .selectedSafeUpdated,
                             .chainInfoChanged] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(reloadData),
                name: notification,
                object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetailsAction)
    }

    @objc private func reloadData() {
        navigationItem.title = dataDecoded?.method ?? placeholderTitle
        cells = []
        buildHeader()
        buildHexData()
        buildParameters()
        tableView.reloadData()
    }

    private func buildHeader() {
        if let tx = multiSendTx {
            let coin = Chain.nativeCoin!
            txBuilder.result = []
            let (name, imageUri) = NamingPolicy.name(for: tx.to.address,
                    info: addressInfoIndex?.values[tx.to]?.addressInfo,
                    chainId: chain.id!)

            var title = "Interact with: "
            if let value = tx.value {
                let amount = Int256(value.value)
                if value != "0" {
                    let nativeCoinDecimals = chain.nativeCurrency!.decimals

                    let decimalAmount = BigDecimal(amount, Int(nativeCoinDecimals))
                    let amount = TokenFormatter().string(
                            from: decimalAmount,
                            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                            forcePlusSign: false
                    )

                    if let currencySymbol = chain.nativeCurrency?.symbol {
                        title = "Interact with (Send \(amount) \(currencySymbol) to): "
                    } else {
                        title = "Interact with (Send \(amount) to): "
                    }
                }
            }
            txBuilder.address(tx.to.address,
                    label: name,
                    title: title,
                    imageUri: imageUri,
                    browseURL: chain.browserURL(address: tx.to.address.checksummed),
                    prefix: chain.shortName,
                    showDelegateWarning: DelegateWarningCalculator.isUntrusted(multiSendTx: tx, addressInfoIndex: addressInfoIndex)
            )
            append(txBuilder.result)
        }
    }

    private func buildHexData() {
        if let data = data {
            let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
            cell.tableView = tableView
            cell.setTitle("Data")
            cell.setExpandableTitle("\(data.data.count) bytes")
            cell.setText(data.description)
            cell.setCopyText(data.description)
            append(cell)
        }
    }

    private func buildParameters() {
        if let params = dataDecoded?.parameters, !params.isEmpty {
            for (index, parameter) in params.enumerated() {
                let paramName = parameter.name.isEmpty ? "Parameter #\(index + 1)" : "\(parameter.name)"
                let paramType = parameter.type.isEmpty ? "" : "(\(parameter.type))"
                append(headerCell("\(paramName)\(paramType):"))
                append(buildValue(parameter.value))
            }
        } else {
            append(textCell("No parameters"))
        }
    }

    private func append(_ cell: UITableViewCell) {
        cells.append(cell)
    }

    private func append(_ value: [UITableViewCell]) {
        cells.append(contentsOf: value)
    }

    private func insert(_ cell: UITableViewCell, at index: Int) {
        cells.insert(cell, at: index)
    }

    private func insert(_ value: [UITableViewCell], at index: Int) {
        cells.insert(contentsOf: value, at: index)
    }

    static func copyValue(_ value: String) {
        Pasteboard.string = value
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    /// Creates appropriate cell for each value type, including array
    /// for which it recursively builds the contents.
    ///
    /// - Parameters:
    ///   - paramValue: parameter value
    ///   - nestingLevel: current nesting level - influences the building
    ///    decisions and indentation level
    private func buildValue(_ paramValue: SCGModels.DataDecoded.Parameter.Value, nestingLevel: Int = 0) -> [UITableViewCell] {

        // we don't want to indent up to 1st-level nested arrays
        let indent: CGFloat = min(max(0, CGFloat(nestingLevel) - 1), 10) * Self.indentWidth

        switch paramValue {

        case .string(let value):
            return [textCell(value, indentation: indent)]

        case .address(let value):
            return [addressCell(value.address, indentation: indent)]

        case .uint256(let value):
            return [textCell(value.description, indentation: indent)]

        case .data(let value):
            return [expandableCell("\(value.data.count) bytes", indentation: indent, content: [hexCell(value.description, indentation: indent)])]

        case .array(let value):
            var content: [UITableViewCell] = []
            if value.isEmpty {
                content = [emptyCell(indentation: indent)]
            } else {
                // recursion
                content = value.flatMap { buildValue($0, nestingLevel: nestingLevel + 1) }
            }

            if nestingLevel == 0 {
                return content
            } else {
                return [expandableCell("array", indentation: indent, content: content)]
            }

        case .unknown:
            return [textCell("Unknown value", indentation: indent)]
        }
    }

    // MARK: - Cell Builder

    private func headerCell(_ text: String, indentation: CGFloat = 0) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailTextCell.self)
        cell.setText(text, style: .headline)
        cell.selectionStyle = .none
        cell.margins.top = 10
        cell.margins.leading += indentation
        return cell
    }

    private func textCell(_ text: String, indentation: CGFloat = 0) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailTextCell.self)
        cell.setText(text, style: .body)
        cell.onTap = {
            Self.copyValue(text)
        }
        cell.margins.leading += indentation
        return cell
    }

    private func emptyCell(indentation: CGFloat = 0) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailTextCell.self)
        cell.setText("empty", style: .bodyTertiary)
        cell.selectionStyle = .none
        cell.margins.leading += indentation
        return cell
    }

    private func addressCell(_ address: Address, indentation: CGFloat = 0) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailAddressCell.self)
        let (name, imageUri) = NamingPolicy.name(for: address,
                                                    info: addressInfoIndex?.values[AddressString(address)]?.addressInfo,
                                                    chainId: chain.id!)
        cell.setAddress(address,
                        label: name,
                        imageUri: imageUri,
                        browseURL: chain.browserURL(address: address.checksummed),
                        prefix: chain.shortName)
        cell.selectionStyle = .none
        cell.margins.leading += indentation
        return cell
    }

    private func hexCell(_ text: String, indentation: CGFloat = 0) -> UITableViewCell {
        let cell = self.tableView.dequeueCell(ActionDetailTextCell.self)
        cell.setText(text, style: .headline)
        cell.onTap = {
            Self.copyValue(text)
        }
        cell.margins.leading += indentation
        return cell
    }

    /// Creates expandable cell that produces other cells when expanded.
    ///
    /// - Parameters:
    ///   - text: Text of the expandable header
    ///   - indentation: indentation width
    ///   - content: closure that produces new cells to insert right after
    ///     the expanded cell.
    private func expandableCell(_ text: String,
                                indentation: CGFloat = 0,
                                content: [UITableViewCell]) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailExpandableCell.self)
        cell.setText(text)
        cell.state = .collapsed
        cell.margins.leading += indentation
        cell.subcells = content

        cell.onTap = { [weak self, weak cell] in
            guard let `self` = self, let cell = cell, let cellIndex = self.cells.firstIndex(of: cell), !cell.subcells.isEmpty else { return }

            switch cell.state {
            case .collapsed:
                // then expand the contents

                cell.state = .expanded

                // create cells
                let insertionIndex = cellIndex.advanced(by: 1)
                self.cells.insert(contentsOf: cell.subcells, at: insertionIndex)

                // update UI
                self.tableView.beginUpdates()
                let insertedPaths = (insertionIndex..<insertionIndex.advanced(by: cell.subcells.count)).map { IndexPath(row: $0, section: 0) }
                self.tableView.insertRows(at: insertedPaths, with: .bottom)
                self.tableView.endUpdates()

            case .expanded:
                // then collapse the contents
                cell.state = .collapsed

                // visit all subcell tree and collapse all

                var allSubcells: [UITableViewCell] = []
                var toVisit: [UITableViewCell] = cell.subcells

                while let sub = toVisit.first {
                    allSubcells.append(toVisit.removeFirst())

                    if let expandable = sub as? ActionDetailExpandableCell {
                        expandable.state = .collapsed

                        toVisit.append(contentsOf: expandable.subcells)
                    }
                }

                // remove all expanded cells
                let deletedIndexes = allSubcells.compactMap { self.cells.firstIndex(of: $0) }
                let deletedPaths = deletedIndexes.map { IndexPath(row: $0, section: 0) }

                // update data source
                self.cells.remove(atOffsets: IndexSet(deletedIndexes))

                // update UI
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletedPaths, with: .top)
                self.tableView.endUpdates()

            }
        }
        return cell
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? ActionDetailTableViewCell {
            cell.onTap()
        }
    }
}
