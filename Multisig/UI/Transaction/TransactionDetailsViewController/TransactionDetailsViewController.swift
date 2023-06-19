//
//  TransactionDetailsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import WalletConnectSwift
import Version

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
    private var ledgerController: LedgerController?
    private var shareButton: UIBarButtonItem!

    private enum TransactionSource {
        case id(String)
        case safeTxHash(Data)
        case data(SCGModels.TransactionDetails)
    }

    private var didTrackScreen: Bool = false
    private var trackedTxStatus: SCGModels.TxStatus?

    private var txSource: TransactionSource!

    private var ledgerKeyInfo: KeyInfo?
    private var keystoneSignFlow: KeystoneSignFlow!
    
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

        builder = TransactionDetailCellBuilder(vc: self, tableView: tableView, chain: safe.chain!)

        updateSafeInfo()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        configureActionButtons()

        for notification in [Notification.Name.ownerKeyImported,
                             .ownerKeyRemoved,
                             .ownerKeyUpdated,
                             .chainInfoChanged,
                             .addressbookChanged,
                             .selectedSafeUpdated,
                             .selectedSafeChanged,
                             .transactionDataInvalidated] {
            notificationCenter.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
        tableView.backgroundColor = .backgroundSecondary

        shareButton = UIBarButtonItem(image: UIImage(named: "ico-share")!.withTintColor(.primary),
                                      style: .plain,
                                      target: self,
                                      action: #selector(didTapShare(_:)))

        navigationItem.rightBarButtonItem = shareButton
    }

    @objc private func didTapShare(_ sender: Any) {
        guard let safe = safe,
              let tx = tx else { return }

        let text = App.configuration.services.webAppURL.appendingPathComponent("\(safe.chain!.shortName!):\(safe.displayAddress)/transactions/\(tx.txId)")
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, success, _, _ in
            if success {
                App.shared.snackbar.show(message: "Transaction link shared")
            }
        }

        present(vc, animated: true, completion: nil)
    }

    private func updateSafeInfo() {
        loadSafeInfoDataTask = clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                             chainId: safe.chain!.id!) { result in
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
        trackScreen()
    }

    private func trackScreen() {
        if !didTrackScreen, let status = trackedTxStatus {
            Tracker.trackEvent(.transactionsDetails, parameters: [
                "status": status.rawValue
            ])
            didTrackScreen = true
        }
    }

    private func trackScreenWithLoadingFailure() {
        // failed to load the status, track without parameters
        if !didTrackScreen {
            Tracker.trackEvent(.transactionsDetails)
        }
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
        // allow executing to anyone with a key
        tx?.multisigInfo?.canSign == true && (showsRejectButton || showsConfirmButton || showsExecuteButton) || showsExecuteButton
    }

    private var showsRejectButton: Bool {
        switch self.tx?.txInfo {
        case .rejection(_):
            return false
        default:
            guard let multisigInfo = tx?.multisigInfo,
                  let status = tx?.txStatus,
                  multisigInfo.canSign
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
        guard let tx = tx else {
            return false
        }
        let result = needsYourExecution(tx: tx)
        return result
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
        let vc = ChooseOwnerKeyViewController(
            owners: signers,
            chainID: safe.chain!.id,
            header: .text(description: descriptionText)
        ) {
            [weak self] keyInfo in

            // dismiss presented ChooseOwnerKeyViewController right after receiving the completion
            self?.dismiss(animated: true) {
                guard let keyInfo = keyInfo else { return }
                self?.sign(keyInfo)
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
        guard let safe = self.safe,
              let chain = self.safe.chain,
              let tx = self.tx else {
              return
          }
        let reviewVC = ReviewExecutionViewController(
            safe: safe,
            chain: chain,
            transaction: tx
        ) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        } onSuccess: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        let navigationController = UINavigationController(rootViewController: reviewVC)
        present(navigationController, animated: true)
    }

    private func sign(_ keyInfo: KeyInfo) {
        guard let tx = tx,
              var transaction = Transaction(tx: tx),
              let safeAddress = try? Address(from: safe.address!),
              let chainId = safe.chain?.id,
              let safeTxHash = transaction.safeTxHash?.description else {
            preconditionFailure("Unexpected Error")            
        }

        transaction.safe = AddressString(safeAddress)
        transaction.safeVersion = safe.contractVersion != nil ? Version(safe.contractVersion!) : nil
        transaction.chainId = chainId

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
            Wallet.shared.sign(transaction, keyInfo: keyInfo) { [unowned self] result in
                do {
                    let signature = try result.get()
                    confirmAndRefresh(safeTxHash: safeTxHash, signature: signature.hexadecimal, keyInfo: keyInfo)

                } catch {
                    onError(GSError.error(description: "Failed to confirm transaction", error: error))
                }
            }

        case .walletConnect:
            let signVC = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: safe.chain!)
            signVC.onSuccess = { [weak self] signature in
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: signature, keyInfo: keyInfo)
            }
            let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
            present(vc, animated: true)

        case .ledgerNanoX:
            let request = SignRequest(title: "Confirm Transaction",
                                      tracking: ["action" : "confirm"],
                                      signer: keyInfo,
                                      hexToSign: safeTxHash)
            let vc = LedgerSignerViewController(request: request)

            present(vc, animated: true, completion: {
                Tracker.trackEvent(.reviewExecutionLedger)
            })

            // needed to fix 'blinking' issue (screen reloads) when
            // cancelling ledger signing on the device.
            // Doing this via this variable 'patch' so that we don't rewrite the ledger implementation just yet.
            var didSign = false

            vc.completion = { [weak self] signature in
                didSign = true
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: signature, keyInfo: keyInfo)
            }

            vc.onClose = { [weak self] in
                if didSign {
                    self?.reloadData()
                }
            }
            
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: transaction.safeTxHash.hash.toHexString(),
                chain: safe.chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned self] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                onError(GSError.KeystoneStartSignFailed())
                return
            }
            
            keystoneSignFlow = signFlow
            keystoneSignFlow.signCompletion = { [weak self] unmarshaledSignature in
                self?.confirmAndRefresh(safeTxHash: safeTxHash, signature: unmarshaledSignature.safeSignature, keyInfo: keyInfo)
            }
            present(flow: keystoneSignFlow)
        }
    }

    private func confirmAndRefresh(safeTxHash: String, signature: String, keyInfo: KeyInfo) {
        super.reloadData()
        confirmDataTask = App.shared.clientGatewayService.asyncConfirm(safeTxHash: safeTxHash,
                                                                       signature: signature,
                                                                       chainId: safe.chain!.id!) {
            [weak self] result in

            // NOTE: sometimes the data of the transaction list is not
            // updated right away, we'll give a moment for the backend
            // to catch up before finishing with this request.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                if case Result.success(_) = result {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        App.shared.snackbar.show(message: "Confirmation successfully submitted")
                        Tracker.trackEvent(
                            .userTransactionConfirmed,
                            parameters: TrackingEvent.keyTypeParameters(keyInfo, parameters: ["source": "tx_details"])
                        )
                    }
                }

                self?.onLoadingCompleted(result: result)
            }
        }
    }

    // MARK: - Loading Data

    override func reloadData() {
        super.reloadData()
        reloadDataTask?.cancel()

        guard let chainId = safe.chain?.id else { return }

        switch txSource {
        case .id(let txID):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(id: txID, chainId: chainId) {
                [weak self] in
                
                self?.onLoadingCompleted(result: $0)
            }
        case .safeTxHash(let safeTxHash):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(safeTxHash: safeTxHash, chainId: chainId) { [weak self] in
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

                self.trackScreenWithLoadingFailure()
            }
        case .success(let details):
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                // Changing source to the transaction ID because of backend issue with caching
                // that happens when loading transaction details by safeTxHash, then creating rejection transaction,
                // then reloading the data - the rejectors field is not returned. This happens because of caching.
                // To avoid that, switch to loading the transaction by id after first data load.
                if let source = self.txSource, case TransactionSource.safeTxHash = source, !details.txId.isEmpty {
                    self.txSource = .id(details.txId)
                }
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

        let transformer = TransactionDataTransformer(safe: self.safe, chain: self.safe.chain!)
        self.tx = transformer.transformed(transaction: self.tx!)

        trackScreen()
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

    // returns the execution keys valid for executing this transaction
    func executionKeys() -> [KeyInfo] {
        // we only know now how to exeucte a safe transaction
        guard tx?.multisigInfo != nil else {
            return []
        }

        guard let safe = safe, let chain = safe.chain else {
            return []
        }

        // all keys that can sign this tx on its chain.
            // currently, only wallet connect keys are chain-specific, so we filter those out.
        guard let allKeys = try? KeyInfo.all(), !allKeys.isEmpty else {
            return []
        }

        let validKeys = allKeys.filter { keyInfo in
            // if it's a wallet connect key which chain doesn't match then do not use it
            if keyInfo.keyType == .walletConnect,
               let chainId = keyInfo.walletConnections?.first?.chainId,
               // when chainId is 0 then it is 'any' chain
               chainId != 0 && String(chainId) != chain.id {
                return false
            }
            // else use the key
            return true
        }
        .filter {
            // filter out ledger until it is supported
            $0.keyType != .ledgerNanoX
        }

        return validKeys
    }

    // returns true if the app has means to execute the transaction and the transaction has all required confirmations
    //TODO: check remaining relays
    func needsYourExecution(tx: SCGModels.TransactionDetails) -> Bool {
        if tx.txStatus == .awaitingExecution,
           let multisigInfo = tx.multisigInfo,
           // unclear why the confirmations only count ecdsa
           tx.ecdsaConfirmations.count >= multisigInfo.confirmationsRequired,
           !executionKeys().isEmpty {
            return true
        }
        return false
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
