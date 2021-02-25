//
//  TransactionDetailsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionDetailsViewController: LoadableViewController, UITableViewDataSource, UITableViewDelegate {
    var clientGatewayService = App.shared.clientGatewayService

    private var cells: [UITableViewCell] = []
    private var tx: SCGModels.TransactionDetails?
    private var reloadDataTask: URLSessionTask?
    private var confirmDataTask: URLSessionTask?
    private var builder: TransactionDetailCellBuilder!
    private var confirmButton: UIButton!

    private enum TransactionSource {
        case id(String)
        case safeTxHash(Data)
        case data(SCGModels.TransactionDetails)
    }

    private var txSource: TransactionSource!

    convenience init(transactionID: String) {
        self.init(namedClass: Self.superclass())
        txSource = .id(transactionID)
    }

    convenience init(safeTxHash: Data) {
        self.init(namedClass: Self.superclass())
        txSource = .safeTxHash(safeTxHash)
    }

    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: Self.superclass())
        txSource = .data(transaction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transaction Details"

        builder = TransactionDetailCellBuilder(vc: self, tableView: tableView)

        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        configureConfirmButton()

        notificationCenter.addObserver(
            self, selector: #selector(lazyReloadData), name: .ownerKeyRemoved, object: nil)
        notificationCenter.addObserver(
            self, selector: #selector(lazyReloadData), name: .ownerKeyImported, object: nil)

        tableView.backgroundColor = .secondaryBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.transactionsDetails)
    }

    // MARK: - Events

    override func didChangeSelectedSafe() {
        let isVisible = isViewLoaded && view.window != nil
        navigationController?.popViewController(animated: isVisible)
    }

    // MARK: - Signing

    fileprivate func configureConfirmButton() {
        // confirm button sticks to the bottom of the screen
        // and is on top of the table view.
        // it is shown only when table view is shown.

        confirmButton = UIButton(type: .custom)
        confirmButton.setText("Confirm", .filled)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmButton)
        NSLayoutConstraint.activate([
            confirmButton.heightAnchor.constraint(equalToConstant: 56),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    override func showOnly(view: UIView) {
        super.showOnly(view: view)
        confirmButton.isHidden = view !== tableView || !showsConfirmButton
    }

    private var showsConfirmButton: Bool  {
        App.configuration.toggles.signing && tx?.txStatus == .awaitingYourConfirmation
    }

    @objc private func didTapConfirm() {
        if App.shared.auth.isPasscodeSet {
            let vc = EnterPasscodeViewController()
            let nav = UINavigationController(rootViewController: vc)
            vc.completion = { [weak self, weak nav] success in
                if success {
                    self?.sign()
                }
                nav?.dismiss(animated: true, completion: nil)
            }
            present(nav, animated: true, completion: nil)
        } else {
            let alertVC = UIAlertController(
                title: "Confirm transaction",
                message: "You are about to confirm the transaction with your currently imported owner key. This confirmation is off-chain. The transaction should be executed separately in the web interface.",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak self] _ in
                self?.sign()
            }))
            present(alertVC, animated: true, completion: nil)
        }
    }

    private func sign() {
        guard let tx = tx,
              let transaction = Transaction(tx: tx) else {
            preconditionFailure("Unexpected Error")            
        }
        super.reloadData()
        do {
            let safeAddress = try Address(from: try Safe.getSelected()!.address!)
            let signature = try SafeTransactionSigner().sign(transaction, by: safeAddress)
            let safeTxHash = transaction.safeTxHash!.description
            confirmDataTask = App.shared.clientGatewayService.asyncConfirm(safeTxHash: safeTxHash, with: signature.value, completion: { [weak self] result in

                // NOTE: sometimes the data of the transaction list is not
                // updated right away, we'll give a moment for the backend
                // to catch up before finishing with this request.
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                    if case Result.success(_) = result {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                            Tracker.shared.track(event: TrackingEvent.transactionDetailsTransactionConfirmed)
                            App.shared.snackbar.show(message: "Confirmation successfully submitted")
                        }
                    }

                    self?.onLoadingCompleted(result: result)
                }
            })
        } catch {
            onError(GSError.error(description: "Failed to confirm transaction", error: error))
        }
    }

    // MARK: - Loading Data

    override func reloadData() {
        super.reloadData()
        reloadDataTask?.cancel()

        switch txSource {
        case .id(let txID):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(id: txID) { [weak self] in
                self?.onLoadingCompleted(result: $0)
            }
        case .safeTxHash(let safeTxHash):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(safeTxHash: safeTxHash) { [weak self] in
                self?.onLoadingCompleted(result: $0)
            }
        case .data(let tx):
            buildCells(from: tx)
            onSuccess()
        case .none:
            preconditionFailure("Developer error: txSource is required")
        }
    }

    private func onLoadingCompleted(result: Result<SCGModels.TransactionDetails, Error>) {
        switch result {
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                // ignore cancellation error due to cancelling the
                // currently running task. Otherwise user will see
                // meaningless message.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                self.onError(GSError.error(description: "Failed to load transaction details", error: error))
            }
        case .success(let details):
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.buildCells(from: details)
                self.onSuccess()
            }
        }
    }

    func buildCells(from tx: SCGModels.TransactionDetails) {
        self.tx = tx

        // artificial tx status
        if self.tx!.needsYourConfirmation {
            self.tx!.txStatus = .awaitingYourConfirmation
        }

        cells = builder.build(self.tx!)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if let disclosureCell = cell as? DetailDisclosingCell {
            disclosureCell.action()
        }
    }

}

extension SCGModels.TransactionDetails {
    var needsYourConfirmation: Bool {
        if txStatus == .awaitingConfirmations,
           let signingKey = PrivateKeyController.signingKeyAddress,
           let signingAddress = AddressString(signingKey),
           case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigTx)? = detailedExecutionInfo,
           multisigTx.isSigner(address: signingAddress) &&
            multisigTx.needsMoreSignatures &&
            !multisigTx.hasConfirmed(address: signingAddress) {
            return true
        }
        return false
    }
}

extension SCGModels.TransactionDetails.DetailedExecutionInfo.Multisig {

    func isSigner(address: AddressString) -> Bool {
        signers.contains(address)
    }

    func hasConfirmed(address: AddressString) -> Bool {
        confirmations.contains { $0.signer == address }
    }

    var needsMoreSignatures: Bool {
        confirmationsRequired > confirmations.count
    }
}
