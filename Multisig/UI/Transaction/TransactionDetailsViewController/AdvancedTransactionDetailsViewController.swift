//
//  AdvancedTransactionDetailsViewController.swift
//  Multisig
//
//  Created by Moaaz on 9/29/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AdvancedTransactionDetailsViewController: UITableViewController {
    private var transaction: SCGModels.TransactionDetails!
    private let namingPolicy = DefaultAddressNamingPolicy()
    private var sections: [Section] = []
    convenience init(_ tx: SCGModels.TransactionDetails) {
        self.init()
        self.transaction = tx
        buildSections(tx)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetailsAdvanced)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Advanced"

        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.estimatedSectionHeaderHeight = BasicHeaderView.headerHeight
    }

    func buildSections(_ tx: SCGModels.TransactionDetails) {
        if let hash = tx.txHash?.description {
            sections.append(Section(title: "Chain transaction data",
                                    items: [SectionItem(title: "Transaction hash:", value: hash)]))
        }

        if let txData = tx.txData {
            var safeTransactionData:[SectionItem] = []
            safeTransactionData.append(SectionItem(title: "To:", value: txData.to))
            safeTransactionData.append(SectionItem(title: "Value:", value: txData.value))
            if let data = txData.hexData {
                safeTransactionData.append(SectionItem(title: "Data:", value: data))
            }

            // TODO: Check
//            if let data = txData.dataDecoded {
//                safeTransactionData.append(SectionItem(title: "Decoded Data:", value: data))
//            }

            safeTransactionData.append(SectionItem(title: "Operation:", value: txData.operation.name))

            sections.append(Section(title: "Safe transaction data", items: safeTransactionData))
        }

        let nonce: String?
        let safeTxHash: String?

        if case SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(let multisigTx)? =
            tx.detailedExecutionInfo {
            nonce = multisigTx.nonce.description
            safeTxHash = multisigTx.safeTxHash.description
        } else {
            nonce = nil
            safeTxHash = nil
        }

        if let nonce = nonce, let safeTxHash = safeTxHash {
            sections.append(Section(title: "",
                                    items: [SectionItem(title: "safeTxHash:", value: safeTxHash),
                                            SectionItem(title: "Nonce:", value: nonce)]))
        }

        switch tx.detailedExecutionInfo {
        case .multisig(let multisigInfo):
            var multiSigTransactionInfo:[SectionItem] = []
            multiSigTransactionInfo.append(SectionItem(title: "safeTxGas:", value: multisigInfo.safeTxGas))
            multiSigTransactionInfo.append(SectionItem(title: "baseGas:", value: multisigInfo.baseGas))
            multiSigTransactionInfo.append(SectionItem(title: "gasPrice:", value: multisigInfo.gasPrice))
            multiSigTransactionInfo.append(SectionItem(title: "gasToken:", value: multisigInfo.gasToken))
            multiSigTransactionInfo.append(SectionItem(title: "refundReceiver:", value: multisigInfo.refundReceiver))

            sections.append(Section(title: "Multisig Data", items: multiSigTransactionInfo))
        case .module(let moduleInfo):
            sections.append(Section(title: "Module Data", items: [SectionItem(title: "Module Address:", value: moduleInfo.address)]))
        default:
            break
        }

        sections = sections.filter({ section in !section.items.isEmpty })
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BasicHeaderView.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(section.title)

        return view
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        if let addressInfo = item.value as? SCGModels.AddressInfo {
            return address(addressInfo.value.address, label: addressInfo.name, title: item.title, imageUri: addressInfo.logoUri, indexPath: indexPath)
        } else if let addressString = item.value as? AddressString {
            return address(addressString.address, label: nil, title: item.title, imageUri: nil, indexPath: indexPath)
        } else if let intValue = item.value as? UInt256String {
            return text(intValue.description, title: item.title, expandableTitle: nil, copyText: intValue.description, indexPath: indexPath)

        } else if let string = item.value as? String {
            return text(string, title: item.title, expandableTitle: nil, copyText: string, indexPath: indexPath)

        } else if let data = item.value as? DataString {
            return text("\(data)", title: item.title, expandableTitle: "\(data.data.count) Bytes", copyText: "\(data)", indexPath: indexPath)

        } else if let string = item.value as? String {
            return text(string, title: item.title, expandableTitle: nil, copyText: string, indexPath: indexPath)
        } else {
            return UITableViewCell()
        }
    }

    func text(_ text: String, title: String, expandableTitle: String?, copyText: String?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self, for: indexPath)
        cell.tableView = tableView
        cell.setTitle(title)
        cell.setText(text)
        cell.setCopyText(copyText)
        cell.setExpandableTitle(expandableTitle)

        return cell
    }

    func address(_ address: Address, label: String?, title: String?, imageUri: URL? = nil, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: label, title: title, imageUri: imageUri)
        return cell
    }
}

fileprivate struct Section {
    let title: String
    let items: [SectionItem]
}

fileprivate struct SectionItem {
    let title: String
    let value: Any
}
