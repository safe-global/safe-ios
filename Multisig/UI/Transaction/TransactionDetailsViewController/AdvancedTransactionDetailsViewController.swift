//
//  AdvancedTransactionDetailsViewController.swift
//  Multisig
//
//  Created by Moaaz on 9/29/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AdvancedTransactionDetailsViewController: UITableViewController {
    private var sections: [Section] = []
    private var chainId: String!
    convenience init(_ tx: SCGModels.TransactionDetails, chainId: String) {
        self.init()
        self.chainId = chainId
        buildSections(tx)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetailsAdvanced)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Advanced"

        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(DetailDisclosingCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.estimatedSectionHeaderHeight = BasicHeaderView.headerHeight
        tableView.estimatedSectionFooterHeight = 0
    }

    func buildSections(_ tx: SCGModels.TransactionDetails) {
        if let hash = tx.txHash?.description {
            sections.append(Section(title: "Chain transaction data",
                                    items: [SectionItem(title: "Transaction hash:", value: hash)]))
        }

        if let txData = tx.txData {
            var safeTransactionData: [SectionItem] = []
            safeTransactionData.append(SectionItem(title: "To:", value: txData.to))
            safeTransactionData.append(SectionItem(title: "Value:", value: txData.value.description))

            if let dataDecoded = txData.dataDecoded {
                let addressInfoIndex = txData.addressInfoIndex
                if dataDecoded.method == "multiSend",
                   let param = dataDecoded.parameters?.first,
                   param.type == "bytes",
                   case let SCGModels.DataDecoded.Parameter.ValueDecoded.multiSend(multiSendTxs)? = param.valueDecoded {
                    safeTransactionData.append(SectionItem(title: "Multisend (\(multiSendTxs.count) actions)",
                                                           value: (multiSendTxs, addressInfoIndex)))
                } else {
                    safeTransactionData.append(SectionItem(title: "Action (\(dataDecoded.method))",
                                                           value: (dataDecoded, addressInfoIndex, tx.txData?.hexData)))
                }
            }

            if let data = txData.hexData {
                safeTransactionData.append(SectionItem(title: "Data:", value: data))
            }

            safeTransactionData.append(SectionItem(title: "Operation:", value: txData.operation.name))

            sections.append(Section(title: "Safe transaction data", items: safeTransactionData))
        }

        if case SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(let multisigTx)? =
            tx.detailedExecutionInfo {
            sections.append(Section(title: "",
                                    items: [SectionItem(title: "safeTxHash:", value: multisigTx.nonce.description),
                                            SectionItem(title: "Nonce:", value: multisigTx.safeTxHash.description)]))
        }

        switch tx.detailedExecutionInfo {
        case .multisig(let multisigInfo):
            var multiSigTransactionInfo: [SectionItem] = []
            multiSigTransactionInfo.append(SectionItem(title: "safeTxGas:", value: multisigInfo.safeTxGas.description))
            multiSigTransactionInfo.append(SectionItem(title: "baseGas:", value: multisigInfo.baseGas.description))
            multiSigTransactionInfo.append(SectionItem(title: "gasPrice:", value: multisigInfo.gasPrice.description))
            multiSigTransactionInfo.append(SectionItem(title: "gasToken:", value: multisigInfo.gasToken.address.addressInfo))
            multiSigTransactionInfo.append(SectionItem(title: "refundReceiver:", value: multisigInfo.refundReceiver))

            sections.append(Section(title: "Multisig Data", items: multiSigTransactionInfo))

            var signatures: [SectionItem] = []
            multisigInfo.confirmations.forEach { confirmation in
                signatures.append(SectionItem(title: nil, value: confirmation.signature))
            }

            sections.append(Section(title: "Signatures", items: signatures))
        case .module(let moduleInfo):
            sections.append(Section(title: "Module Data", items: [SectionItem(title: "Module Address:", value: moduleInfo.address)]))
        default:
            break
        }

        sections = sections.filter { section in !section.items.isEmpty }
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = sections[section]
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(section.title)
        return view
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        if let addressInfo = item.value as? SCGModels.AddressInfo {
            return address(addressInfo.value.address,
                           label: addressInfo.name,
                           title: item.title,
                           imageUri: addressInfo.logoUri,
                           indexPath: indexPath)
        } else if let addressInfo = item.value as? AddressInfo {
            return address(addressInfo.address,
                           label: addressInfo.name,
                           title: item.title,
                           imageUri: addressInfo.logoUri,
                           indexPath: indexPath)
        }
        else if let string = item.value as? String {
            return text(string, title: item.title, expandableTitle: nil, copyText: string, indexPath: indexPath)
        } else if let data = item.value as? DataString {
            return text("\(data)", title: item.title,
                        expandableTitle: "\(data.data.count) Bytes",
                        copyText: "\(data)",
                        indexPath: indexPath)
        } else if let multiSendDataDecoded = item.value as? ([SCGModels.DataDecoded.Parameter.ValueDecoded.MultiSendTx],
                                                             SCGModels.AddressInfoIndex) {
            return disclosure(text: item.title ?? "", indexPath: indexPath) { [weak self] in
                guard let `self` = self else { return }
                let root = MultiSendListTableViewController(transactions: multiSendDataDecoded.0,
                                                            addressInfoIndex: multiSendDataDecoded.1,
                                                             chainId: self.chainId)
                 let vc = RibbonViewController(rootViewController: root)
                self.show(vc, sender: self)
             }
        } else if let actionDataDecoded = item.value as? (SCGModels.DataDecoded,
                                                          SCGModels.AddressInfoIndex?, DataString?) {
            return disclosure(text: item.title ?? "", indexPath: indexPath) { [weak self] in
                guard let `self` = self else { return }
                let root = ActionDetailViewController(decoded: actionDataDecoded.0,
                                                      addressInfoIndex: actionDataDecoded.1,
                                                      chainId: self.chainId,
                                                      data: actionDataDecoded.2)
                let vc = RibbonViewController(rootViewController: root)
                self.show(vc, sender: self)
            }
        } else {
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? DetailDisclosingCell {
            cell.action()
        }
    }

    func text(_ text: String, title: String?, expandableTitle: String?, copyText: String?, indexPath: IndexPath) -> UITableViewCell {
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

    func disclosure(text: String, indexPath: IndexPath, action: @escaping () -> Void) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailDisclosingCell.self, for: indexPath)
        cell.action = action
        cell.setText(text)
        return cell
    }
}

fileprivate struct Section {
    let title: String
    let items: [SectionItem]
}

fileprivate struct SectionItem {
    let title: String?
    let value: Any
}
