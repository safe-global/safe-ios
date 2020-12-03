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

        // TODO: replace with AddressInfo when merged.
        typealias AddressInfo = Address

        func confirmation(_ confirmations: [AddressInfo], required: Int, status: SCG.TxStatus, executor: AddressInfo?) {

        }

        func status(_ status: SCG.TxStatus, type: String, icon: UIImage) {

        }

        func incomingTransfer(value: UInt256, decimals: Int, symbol: String, icon: UIImage, detail: String?, sender: AddressInfo) {

        }

        func outgoingTransfer(value: UInt256, decimals: Int, symbol: String, icon: UIImage, detail: String?, recipient: AddressInfo) {

        }

        func address(_ address: AddressInfo, title: String?) {

        }

        func addressAndText(_ address: AddressInfo, addressTitle: String, text: String, textTitle: String) {

        }

        func addresses(_ accounts: [(account: AddressInfo, title: String)]) {

        }

        buildTransaction()

        return result
    }
}
