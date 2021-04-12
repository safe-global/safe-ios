//
//  WCTransactionConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import Kingfisher
import SwiftCryptoTokenFormatter

fileprivate protocol SectionItem {}

class WCTransactionConfirmationViewController: UIViewController {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!

    var onReject: (() -> Void)?
    var onSubmit: (() -> Void)?

    private var transaction: Transaction!
    private var session: Session!

    enum Section {
        case basic
        case advanced

        enum Basic: SectionItem {
            case safe(UITableViewCell)
            case transaction(UITableViewCell)
            case data(UITableViewCell)
            case advanced(UITableViewCell)
        }

        enum Advanced: SectionItem {
            case nonce(UITableViewCell)
            case safeTxGas(UITableViewCell)
        }
    }

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()

    private var isAdvancedOptionsShown = false

    @IBAction func reject(_ sender: Any) {
        onReject?()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func submit(_ sender: Any) {
        onSubmit?()
        dismiss(animated: true, completion: nil)
    }

    convenience init(transaction: Transaction, topic: String) {
        self.init()
        self.transaction = transaction
        self.session = try! Session.from(WCSession.get(topic: topic)!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if !session.dAppInfo.peerMeta.icons.isEmpty {
            let imageUrl = session.dAppInfo.peerMeta.icons[0]
            dappImageView.kf.setImage(with: imageUrl, placeholder: #imageLiteral(resourceName: "ico-empty-circle"))
        } else {
            dappImageView.image = #imageLiteral(resourceName: "ico-empty-circle")
        }
        dappNameLabel.text = session.dAppInfo.peerMeta.name
        dappNameLabel.setStyle(.headline)

        rejectButton.setText("Reject", .filledError)
        submitButton.setText("Submit", .filled)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(BasicCell.self)

        tableView.separatorStyle = .none

        buildSections()
    }

    private func buildSections() {
        let advancedSectionItems = !isAdvancedOptionsShown ? [] : [
            Section.Advanced.nonce(infoCell(title: "nonce", value: transaction.nonce.description)),
            Section.Advanced.safeTxGas(infoCell(title: "safeTxGas", value: transaction.safeTxGas.description))
        ]
        sections = [
            (section: .basic, items: [
                Section.Basic.safe(safeCell()),
                Section.Basic.transaction(transactionCell()),
                Section.Basic.data(dataCell()),
                Section.Basic.advanced(advancedCell())
            ]),
            (section: .advanced, items: advancedSectionItems)
        ]
    }

    private func reloadAdvancedSection() {
        buildSections()
        tableView.beginUpdates()
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .automatic)
        let advancedRows = [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1)
        ]
        if isAdvancedOptionsShown {
            tableView.insertRows(at: advancedRows, with: .bottom)
        } else {
            tableView.deleteRows(at: advancedRows, with: .fade)
        }
        tableView.endUpdates()
    }

    private func safeCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        cell.setAccount(
            address: transaction.safe!.address,
            label: Safe.cachedName(by: transaction.safe!)
        )
        cell.selectionStyle = .none
        return cell
    }

    private func transactionCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailTransferInfoCell.self)

        let eth = App.shared.tokenRegistry.token(address: .ether)!
        let decimalAmount = BigDecimal(
            Int256(transaction.value.value) * -1,
            eth.decimals.map { Int($0) }!
        )
        let amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ","
        )
        let tokenText = "\(amount) \(eth.symbol)"
        let tokenDetail = amount == "0" ? "\(transaction.data?.data.count ?? 0) Bytes" : nil

        cell.setToken(text: tokenText, style: .secondary)
        cell.setToken(image: UIImage(named: "ico-ether"))
        cell.setDetail(tokenDetail)
        cell.setAddress(transaction.to.address, label: nil, imageUri: nil)
        cell.setOutgoing(true)
        cell.selectionStyle = .none

        return cell
    }

    private func dataCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
        let data = transaction.data?.description ?? ""
        cell.tableView = tableView
        cell.setTitle("data")
        cell.setText(data)
        cell.setCopyText(data)
        cell.setExpandableTitle("\(transaction.data?.data.count ?? 0) Bytes")
        cell.selectionStyle = .none
        return cell
    }

    private func advancedCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self)
        cell.setTitle("Advanced")
        let image = UIImage(systemName: isAdvancedOptionsShown ? "chevron.up" : "chevron.down")!
            .applyingSymbolConfiguration(.init(weight: .bold))!
        cell.setDisclosureImage(image)
        cell.setDisclosureImageTintColor(.secondaryLabel)
        cell.selectedBackgroundView = UIView()
        return cell
    }

    private func infoCell(title: String, value: String) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self)
        cell.setTitle(title)
        cell.setInfo(value)
        cell.selectionStyle = .none
        return cell
    }
}

extension WCTransactionConfirmationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.safe(let cell): return cell
        case Section.Basic.transaction(let cell): return cell
        case Section.Basic.data(let cell): return cell
        case Section.Basic.advanced(let cell): return cell
        case Section.Advanced.nonce(let cell): return cell
        case Section.Advanced.safeTxGas(let cell): return cell
        default: return UITableViewCell()
        }
    }
}

extension WCTransactionConfirmationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case Section.Basic.advanced(_) = sections[indexPath.section].items[indexPath.row] else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        isAdvancedOptionsShown.toggle()
        reloadAdvancedSection()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.advanced(_): return BasicCell.rowHeight
        default: return UITableView.automaticDimension
        }
    }
}
