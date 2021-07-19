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
    private var rejectTask: URLSessionTask?
    private var builder: TransactionDetailCellBuilder!
    private var confirmButton: UIButton!
    private var rejectButton: UIButton!
    private var executeButton: UIButton!
    private var actionsContainerView: UIStackView!

    private var pendingExecution = false
    private var safe: Safe!
    private var loadSafeInfoDataTask: URLSessionTask?

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

        safe = try! Safe.getSelected()!

        builder = TransactionDetailCellBuilder(vc: self, tableView: tableView, networkId: safe.network!.chainId!)

        updateSafeInfo()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        configureActionButtons()

        for notification in [Notification.Name.ownerKeyImported, .ownerKeyRemoved, .ownerKeyUpdated, .networkInfoChanged] {
            notificationCenter.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
        tableView.backgroundColor = .secondaryBackground
    }

    private func updateSafeInfo() {
        loadSafeInfoDataTask = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                             networkId: safe.network!.chainId!) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let safeInfo):
                    self?.safe.update(from: safeInfo)
                    self?.onSuccess()
                case .failure(_):
                    break
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionsDetails)
    }

    // MARK: - Events

    override func didChangeSelectedSafe() {
        let isVisible = isViewLoaded && view.window != nil
        navigationController?.popViewController(animated: isVisible)
    }

    // MARK: - Buttons

    fileprivate func configureActionButtons() {
        // Actions Container View sticks to the bottom of the screen
        // and is on top of the table view.
        // it is shown only when table view is shown.

        actionsContainerView = UIStackView()
        actionsContainerView.axis = .horizontal
        actionsContainerView.distribution = .fillEqually
        actionsContainerView.alignment = .fill
        actionsContainerView.spacing = 20
        actionsContainerView.translatesAutoresizingMaskIntoConstraints = false

        rejectButton = UIButton(type: .custom)
        rejectButton.setText("Reject", .filledError)
        rejectButton.addTarget(self, action: #selector(didTapReject), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(rejectButton)

        confirmButton = UIButton(type: .custom)
        confirmButton.setText("Confirm", .filled)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(confirmButton)

        executeButton = UIButton(type: .custom)
        executeButton.setText("Execute", .filled)
        executeButton.addTarget(self, action: #selector(didTapExecute), for: .touchUpInside)
        actionsContainerView.addArrangedSubview(executeButton)

        view.addSubview(actionsContainerView)
        NSLayoutConstraint.activate([
            actionsContainerView.heightAnchor.constraint(equalToConstant: 56),
            actionsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            actionsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    override func showOnly(view: UIView) {
        super.showOnly(view: view)
        actionsContainerView.isHidden = view !== tableView || !showsActionsViewContrainer
        confirmButton.isHidden = !showsConfirmButton
        rejectButton.isHidden = !showsRejectButton
        executeButton.isHidden = !showsExecuteButton

        confirmButton.isEnabled = enableConfirmButton
        rejectButton.isEnabled = enableRejectionButton
        executeButton.isEnabled = !pendingExecution
    }

    private var showsActionsViewContrainer: Bool  {
        tx?.multisigInfo?.canSign == true && (showsRejectButton || showsConfirmButton || showsExecuteButton)
    }

    private var showsRejectButton: Bool {
        switch self.tx?.txInfo {
        case .rejection(_):
            return false
        default:
            guard let multisigInfo = tx?.multisigInfo,
                  let status = tx?.txStatus
                    else { return false }

            if status == .awaitingExecution && !multisigInfo.isRejected() && !pendingExecution {
                 return true
            } else if status.isAwatingConfiramtions {
                return true
            }

            return false
        }
    }

    private var showsConfirmButton: Bool {
        switch self.tx?.txInfo {
        case .rejection(_):
            if tx!.txStatus.isAwatingConfiramtions,
               let multisigInfo = tx!.multisigInfo,
               multisigInfo.canSign {
                return true
            }
            return false
        default:
            return tx?.txStatus.isAwatingConfiramtions ?? false
        }
    }

    private var showsExecuteButton: Bool {
        guard let nonce = safe.nonce, nonce == tx?.multisigInfo?.nonce.value else {
            return false
        }
        return tx?.needsYourExecution ?? false
    }

    private var enableRejectionButton: Bool {
        if case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigTx)? = tx?.detailedExecutionInfo,
           !multisigTx.isRejected(),
           showsRejectButton {
            return true
        }

        return false
    }

    private var enableConfirmButton: Bool {
        tx?.needsYourConfirmation ?? false
    }

    // MARK: - Signing, Rejection, Execution

    @objc private func didTapConfirm() {
        guard let signers = tx?.multisigInfo?.signerKeys() else {
            assertionFailure()
            return
        }
        let descriptionText = "You are about to confirm this transaction. This happens off-chain. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: signers, descriptionText: descriptionText) {
            [unowned self] keyInfo in

            // dismiss presented ChooseOwnerKeyViewController right after receiving the completion
            dismiss(animated: true) {
                guard let keyInfo = keyInfo else { return }
                sign(keyInfo)
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    @objc private func didTapReject() {
        guard let transaction = tx else { fatalError() }
        let confirmRejectionViewController = RejectionConfirmationViewController(transaction: transaction)
        show(confirmRejectionViewController, sender: self)
    }

    @objc private func didTapExecute() {
        guard let signers = tx?.multisigInfo?.executionKeys() else {
            return
        }

        let descriptionText = "You are about to execute this transaction. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: signers,
                                              descriptionText: descriptionText) { [unowned self] keyInfo in
            dismiss(animated: true) {
                if let keyInfo = keyInfo {
                    execute(keyInfo)
                }
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    private func sign(_ keyInfo: KeyInfo) {
        guard let tx = tx,
              var transaction = Transaction(tx: tx),
              let safeAddress = try? Address(from: safe.address!),
              let chainId = safe.network?.chainId,
              let safeTxHash = transaction.safeTxHash?.description else {
            preconditionFailure("Unexpected Error")            
        }
        super.reloadData()

        transaction.safe = AddressString(safeAddress)
        transaction.safeVersion = safe.contractVersion
        transaction.chainId = chainId

        switch keyInfo.keyType {

        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(transaction, keyInfo: keyInfo)
                confirmAndRefresh(safeTxHash: safeTxHash, signature: signature.hexadecimal, keyType: keyInfo.keyType)
            } catch {
                onError(GSError.error(description: "Failed to confirm transaction", error: error))
            }

        case .walletConnect:
            WalletConnectClientController.shared.sign(transaction: transaction, from: self) {
                [weak self] signature in
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: signature, keyType: keyInfo.keyType)
            }

            WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
        }

    }

    private func confirmAndRefresh(safeTxHash: String, signature: String, keyType: KeyType) {
        confirmDataTask = App.shared.clientGatewayService.asyncConfirm(safeTxHash: safeTxHash,
                                                                       signature: signature,
                                                                       networkId: safe.network!.chainId!) {
            [weak self] result in

            // NOTE: sometimes the data of the transaction list is not
            // updated right away, we'll give a moment for the backend
            // to catch up before finishing with this request.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                if case Result.success(_) = result {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        App.shared.snackbar.show(message: "Confirmation successfully submitted")

                        switch keyType {
                        case .deviceGenerated, .deviceImported:
                            Tracker.trackEvent(.transactionDetailsTransactionConfirmed)
                        case .walletConnect:
                            Tracker.trackEvent(.transactionDetailsTxConfirmedWC)
                        }
                    }
                }

                self?.onLoadingCompleted(result: result)
            }
        }
    }

    private func execute(_ keyInfo: KeyInfo) {
        guard let tx = tx,
              var transaction = Transaction(tx: tx),
              let multisigInfo = tx.multisigInfo,
              keyInfo.keyType == .walletConnect else {
            preconditionFailure("Unexpected Error")
        }
        super.reloadData()

        do {
            let safeAddress = try Address(from: safe.address!)
            transaction.safe = AddressString(safeAddress)
        } catch {
            onError(GSError.error(description: "Failed to execute transaction", error: error))
        }

        WalletConnectClientController.shared.execute(
            transaction: transaction,
            confirmations: tx.ecdsaConfirmations,
            confirmationsRequired: multisigInfo.confirmationsRequired,
            rpcURL: safe.network!.authenticatedRpcUrl,
            from: self,
            onSend: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
                    case .failure(let error):
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Failed to execute transaction", error: error))
                    }
                }
            },
            onResult: { result in
                DispatchQueue.main.async { [unowned self] in
                    switch result {
                    case .success(let hash):
                        presentedViewController?.dismiss(animated: true)
                        self.pendingExecution = true
                        self.reloadData()
                        App.shared.snackbar.show(message: "Transaction submitted. Transaction hash: \(hash)")
                        Tracker.trackEvent(.transactionDetailsTxExecutedWC)

                    case .failure(let error):
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Failed to execute transaction", error: error))
                    }
                }
            })
    }

    // MARK: - Loading Data

    override func reloadData() {
        super.reloadData()
        reloadDataTask?.cancel()

        switch txSource {
        case .id(let txID):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(id: txID, networkId: safe.network!.chainId!) {
                [weak self] in
                
                self?.onLoadingCompleted(result: $0)
            }
        case .safeTxHash(let safeTxHash):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(safeTxHash: safeTxHash, networkId: safe.network!.chainId!) { [weak self] in
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
        if txStatus.isAwatingConfiramtions,
           let multisigInfo = multisigInfo,
           !multisigInfo.signerKeys().isEmpty,
           multisigInfo.needsMoreSignatures {
            return true
        }
        return false
    }

    var needsYourExecution: Bool {
        if txStatus == .awaitingExecution,
           let multisigInfo = multisigInfo,
           ecdsaConfirmations.count >= multisigInfo.confirmationsRequired,
           !multisigInfo.executionKeys().isEmpty {
            return true
        }
        return false
    }

    var ecdsaConfirmations: [SCGModels.Confirmation] {
        guard let multisigInfo = multisigInfo else { return [] }
        return multisigInfo.confirmations.filter {
            $0.signature.data.bytes.last ?? 0 > 26
        }
    }

    var multisigInfo: SCGModels.TransactionDetails.DetailedExecutionInfo.Multisig? {
        if case let SCGModels.TransactionDetails.DetailedExecutionInfo.multisig(multisigTx)? = detailedExecutionInfo {
            return multisigTx
        }

        return nil
    }
}

extension SCGModels.TransactionDetails.DetailedExecutionInfo.Multisig {
    var needsMoreSignatures: Bool {
        confirmationsRequired > confirmations.count
    }

    func hasRejected(address: AddressString) -> Bool {
        rejectors?.map(\.value).contains(address) ?? false
    }

    func isRejected() -> Bool {
        if let rejectors = rejectors, !rejectors.isEmpty {
            return true
        } else {
            return false
        }
    }

    func signerKeys() -> [KeyInfo] {
        let confirmationAdresses = confirmations.map({ $0.signer.value })

        let remainingSigners = signers.map(\.value).filter({
            !confirmationAdresses.contains($0)
        }).map( { $0.address } )

        return (try? KeyInfo.keys(addresses: remainingSigners)) ?? []
    }

    // In general, a transaction can be executed with any ethereum key.
    // However, we restrict the ability to execute only to owners for additional protection.
    func executionKeys() -> [KeyInfo] {
        let signerAddresses = signers.map(\.value).map( { $0.address } )
        guard !((try? KeyInfo.keys(addresses: signerAddresses)) ?? []).isEmpty else {
            return []
        }

        // but any WalletConnect key can execute a transaction
        let keys = (try? KeyInfo.all()) ?? []
        return keys.filter { $0.keyType == .walletConnect }
    }

    func rejectorKeys() -> [KeyInfo] {
        let rejectorsAdresses = rejectors?.map(\.value) ?? []
        let remainingSigners = signers.map(\.value).filter({
            !rejectorsAdresses.contains($0)
        }).map( { $0.address } )

        return (try? KeyInfo.keys(addresses: remainingSigners)) ?? []
    }

    var canSign: Bool {
        let signerAddresses = signers.map(\.value).map( { $0.address } )
        let keys = (try? KeyInfo.keys(addresses: signerAddresses)) ?? []
        return !keys.isEmpty
    }
}

extension SCGModels.TxStatus {
    var isAwatingConfiramtions: Bool {
        [.awaitingYourConfirmation, .awaitingConfirmations].contains(self)
    }
}
