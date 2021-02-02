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

    typealias TransactionCell = (title: String, value: String)

    private var cells = [TransactionCell]()

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

        rejectButton.setText("Reject", .bordered)
        submitButton.setText("Submit", .filled)

        tableView.dataSource = self
        tableView.registerCell(InfoCell.self)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false

        buildCells()
    }

    private func buildCells() {
        cells = [
            (title: "to", value: transaction.to.description),
            (title: "value", value: transaction.value.description),
            (title: "data", value: transaction.data.description),
            (title: "safeTxGas", value: transaction.safeTxGas.description),
            (title: "nonce", value: transaction.nonce.description)
        ]
    }
}

extension WCTransactionConfirmationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self)
        cell.setTitle(cells[indexPath.row].title)
        cell.setInfo(cells[indexPath.row].value)
        return cell
    }
}
