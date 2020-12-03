//
//  TransactionDetailCellBuilder.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class TransactionDetailCellBuilder {

    private weak var vc: UIViewController!
    private weak var tableView: UITableView!

    init(vc: UIViewController, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView

        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(DetailConfirmationCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailAccountAndTextCell.self)
        tableView.registerCell(DetailMultiAccountsCell.self)
    }

    func build(from tx: SCG.TransactionDetails) -> [UITableViewCell] {
        var result: [UITableViewCell] = []

        func buildCreation() {
        }

        func buildTransaction() {
            text("Value", title: "No copy", expandableTitle: nil, copyText: nil)
            text("Value", title: "Copy value", expandableTitle: nil, copyText: "Copied value")
            text("Value\nMultiline\nValue", title: "Expandable", expandableTitle: "collapsed", copyText: "copy text")
            text("Value\nMultiline\nValue", title: "No Copy", expandableTitle: "value inside", copyText: "copy text")

            address(.zero, label: "name", title: "This is address:")

            address(.zero, label: nil, title: "Without label:")

            address(.zero, label: nil, title: nil)

            addressAndText(.zero, label: nil, addressTitle: "Address:", text: "Some value", textTitle: "Some title")

            addresses([(address: .zero, label: nil, title: "Remove owner:"),
                       (address: .zero, label: nil, title: "Add owner:")])

            confirmation([.zero, .zero], required: 1, status: .awaitingConfirmations, executor: .zero)

            confirmation([.zero, .zero], required: 0, status: .awaitingExecution, executor: .zero)

            // this should not happen, i.e. this will be a backend error
            confirmation([.zero, .zero], required: 0, status: .awaitingConfirmations, executor: .zero)


            confirmation([.zero, .zero], required: 1, status: .awaitingYourConfirmation, executor: .zero)
            confirmation([.zero, .zero], required: 1, status: .failed, executor: .zero)
            confirmation([.zero, .zero], required: 1, status: .success, executor: .zero)
            confirmation([.zero, .zero], required: 1, status: .cancelled, executor: .zero)
        }

        func disclosure(text: String, action: () -> Void) {

        }

        func externalURL(text: String, url: URL) {

        }

        func text(_ text: String, title: String, expandableTitle: String?, copyText: String?) {
            let indexPath = IndexPath(row: result.count, section: 0)
            let cell = tableView.dequeueCell(DetailExpandableTextCell.self, for: indexPath)
            cell.tableView = tableView
            cell.setTitle(title)
            cell.setText(text)
            cell.setCopyText(copyText)
            cell.setExpandableTitle(expandableTitle)
            result.append(cell)
        }

        func confirmation(_ confirmations: [Address], required: Int, status: SCG.TxStatus, executor: Address?) {
            let indexPath = IndexPath(row: result.count, section: 0)
            let cell = tableView.dequeueCell(DetailConfirmationCell.self, for: indexPath)
            cell.setConfirmations(confirmations,
                                  required: required,
                                  status: status,
                                  executor: executor)
            result.append(cell)
        }

        func status(_ status: SCG.TxStatus, type: String, icon: UIImage) {

        }

        func incomingTransfer(value: UInt256, decimals: Int, symbol: String, icon: UIImage, detail: String?, sender: Address) {

        }

        func outgoingTransfer(value: UInt256, decimals: Int, symbol: String, icon: UIImage, detail: String?, recipient: Address) {

        }

        func address(_ address: Address, label: String?, title: String?) {
            let indexPath = IndexPath(row: result.count, section: 0)
            let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
            cell.setAccount(address: address.checksummed, label: label, title: title)
            result.append(cell)
        }

        func addressAndText(_ address: Address, label: String?, addressTitle: String, text: String, textTitle: String) {
            let indexPath = IndexPath(row: result.count, section: 0)
            let cell = tableView.dequeueCell(DetailAccountAndTextCell.self, for: indexPath)
            cell.setText(title: textTitle, details: text)
            cell.setAccount(address: address, label: label, title: addressTitle)
            result.append(cell)
        }

        func addresses(_ accounts: [(address: Address, label: String?, title: String?)]) {
            let indexPath = IndexPath(row: result.count, section: 0)
            let cell = tableView.dequeueCell(DetailMultiAccountsCell.self, for: indexPath)
            cell.setAccounts(accounts: accounts)
            result.append(cell)
        }

        buildTransaction()

        return result
    }
}
