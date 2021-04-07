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

    private var cells = [UITableViewCell]()

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

        rejectButton.setText("Reject", .primary)
        submitButton.setText("Submit", .filled)

        tableView.dataSource = self

        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailAccountCell.self)

        tableView.registerCell(InfoCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)



        tableView.separatorStyle = .none
        tableView.allowsSelection = false

        buildCells()
    }

    private func buildCells() {
        cells.append(contentsOf: [
            safeCell(),
            transactionCell(),
            dataCell(),
            infoCell(title: "nonce", value: transaction.nonce.description),
            infoCell(title: "safeTxGas", value: transaction.safeTxGas.description)
        ])
    }

    private func safeCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        cell.setAccount(
            address: transaction.safe!.address,
            label: Safe.cachedName(by: transaction.safe!)
        )
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
        return cell
    }

    private func infoCell(title: String, value: String) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self)
        cell.setTitle(title)
        cell.setInfo(value)
        return cell
    }
}

extension WCTransactionConfirmationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }
}
