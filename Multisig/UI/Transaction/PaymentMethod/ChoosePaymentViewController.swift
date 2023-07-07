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
    var relaysRemaining: Int = 0
    var relaysLimit: Int = 0
    var userSelectedSigner = true
    var chooseRelay: () -> Void = { }
    var chooseSigner: () -> Void = { }

    private let ROW_RELAYER = 0
    private let ROW_SIGNER_ACCOUNT = 2

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose how to pay"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))

        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SpacingCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil
        tableView.backgroundColor = .backgroundSecondary

        if userSelectedSigner {
            selectSignerAccountOption()
        } else {
            selectRelayerOption()
        }
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
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BorderedInnerTableCell.self, for: indexPath)

        cell.tableView.registerCell(PaymentMethodCell.self)
        cell.tableView.backgroundColor = .backgroundSecondary
        cell.tableView.separatorStyle = .none
        cell.selectionStyle = .none
        switch(indexPath.row) {
        case 0:
            cell.setCells([buildRelayerCell(tableView: cell.tableView)])
            if relaysRemaining < ReviewExecutionViewController.MIN_RELAY_TXS_LEFT {
                cell.isUserInteractionEnabled = false
            } else {
                cell.onCellTap = { [weak self] _ in
                    guard let self = self else { return }
                    if self.relaysRemaining <= ReviewExecutionViewController.MIN_RELAY_TXS_LEFT { return }
                    LogService.shared.debug("Select relay")

                    self.unsellectOptions()
                    self.selectRelayerOption()

                    self.chooseRelay()
                    self.dismiss(animated: true)
                }
                cell.isUserInteractionEnabled = true
            }
        case 1:
            return tableView.spacingCell(indexPath: indexPath)
        case 2:
            cell.setCells([buildSignerAccountCell(tableView: cell.tableView)])
            cell.onCellTap = { [weak self] _ in
                guard let self = self else { return }
                LogService.shared.debug("Select signer account")

                self.unsellectOptions()
                self.selectSignerAccountOption()

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
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.setSignerAccount()
        return cell
    }

    private func buildRelayerCell(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(PaymentMethodCell.self)
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.setRelaying(relaysRemaining, relaysLimit)
        return cell
    }

    private func selectSignerAccountOption() {
        tableView.selectRow(at: IndexPath(row: ROW_SIGNER_ACCOUNT, section: 0), animated: false, scrollPosition: .none)
    }

    private func unsellectOptions() {
        tableView.deselectRow(at: IndexPath(index: ROW_RELAYER), animated: true)
        tableView.deselectRow(at: IndexPath(index: ROW_SIGNER_ACCOUNT), animated: true)
    }

    private func selectRelayerOption() {
        tableView.selectRow(at: IndexPath(row: ROW_RELAYER, section: 0), animated: false, scrollPosition: .none)
    }
}
