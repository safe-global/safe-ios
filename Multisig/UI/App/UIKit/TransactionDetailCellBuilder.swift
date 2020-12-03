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

        func expandableText(_ text: String, title: String, collapsedText: String, copyText: String?) {
            
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

        func addressAndText(_ address: Address, addressTitle: String, text: String, textTitle: String) {

        }

        func addresses(_ accounts: [(account: Address, title: String)]) {

        }

        buildTransaction()

        return result
    }
}
