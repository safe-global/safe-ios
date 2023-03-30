//
//  ChoosePaymentViewController.swift
//  Multisig
//
//  Created by Vitaly on 23.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChoosePaymentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView!
    var remainingRelays: Int = 0
    var chooseRelay: () -> Void = { }
    var chooseSigner: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose how to pay"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))

        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayChoosePayment)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BorderedInnerTableCell.self, for: indexPath)
        //cell.selectionStyle = .gray

        cell.tableView.registerCell(PaymentMethodCell.self)
        switch(indexPath.row) {
        case 0:
            cell.setCells([buildRelayerCell(tableView: cell.tableView)])
            if remainingRelays < ReviewExecutionViewController.MIN_RELAY_TXS_LEFT {
                cell.isEnabled(false)
                cell.onCellTap = { [weak self] _ in
                    guard let self = self else { return }
                    LogService.shared.debug("Select relay")

                    self.chooseRelay()
                    self.dismiss(animated: true)
                }
            } else {
                cell.isEnabled(true)
            }

        case 1:
            cell.setCells([buildSignerAccountCell(tableView: cell.tableView)])
            cell.onCellTap = { [weak self] _ in
                guard let self = self else { return }
                LogService.shared.debug("Select signer account")

                self.chooseSigner()
                self.dismiss(animated: true)
            }
        default:
            break
        }

        return cell
    }

    private func buildSignerAccountCell(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(PaymentMethodCell.self)
        cell.accessoryType = .none
        cell.setSignerAccount()
        return cell
    }

    private func buildRelayerCell(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(PaymentMethodCell.self)
        cell.accessoryType = .none
        cell.setRelaying(remainingRelays, ReviewExecutionViewController.MAX_RELAY_TXS)
        return cell
    }
}

extension UITableViewCell {
    func isEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        subviews.forEach { subview in
            subview.isUserInteractionEnabled = enabled
            subview.alpha = enabled ? 1 : 0.5
        }
    }
}
