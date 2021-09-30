//
//  RejectionConfirmationViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class RejectionConfirmationViewController: UIViewController {

    @IBOutlet private weak var contentContainerView: UIStackView!
    @IBOutlet private weak var loadingView: LoadingView!
    @IBOutlet private weak var createOnChainRejectionLabel: UILabel!
    @IBOutlet private weak var collectConfirmationsLabel: UILabel!
    @IBOutlet private weak var executeOnChainRejectionLabel: UILabel!
    @IBOutlet private weak var initialTransactionLabel: UILabel!
    @IBOutlet private weak var rejectionButton: UIButton!
    @IBOutlet private weak var readMoreLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    private var transaction: SCGModels.TransactionDetails!
    private lazy var rejectionTransaction: Transaction = {
        Transaction.rejectionTransaction(safeAddress: safe.addressValue,
                                         nonce: transaction.multisigInfo!.nonce,
                                         safeVersion: safe.contractVersion!,
                                         chainId: safe.chain!.id!)
    }()
    private var safe: Safe!
    private var keyInfo: KeyInfo?
    private var ledgerController: LedgerController?

    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: RejectionConfirmationViewController.self)
        self.transaction = transaction
        self.safe = try! Safe.getSelected()!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rejectionButton.setText("Reject transaction", .filledError)
        navigationItem.title = "Reject Transaction"

        createOnChainRejectionLabel.setStyle(.footnote3)
        collectConfirmationsLabel.setStyle(.footnote2)
        executeOnChainRejectionLabel.setStyle(.footnote2)
        initialTransactionLabel.setStyle(.footnote2)
        descriptionLabel.setStyle(.primary)

        readMoreLabel.hyperLinkLabel("Advanced users can create a non-empty (useful) transaction with the same nonce (in the web interface only). Learn more in this article: ",
                                     linkText: "Why do I need to pay for rejecting a transaction?")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didRemoveOwner(_:)),
            name: .ownerKeyRemoved,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.transactionDetailsRejectionConfirmation)
    }

    @objc private func didRemoveOwner(_ notification: Notification) {
        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }

    @IBAction func rejectButtonTouched(_ sender: Any) {
        guard let rejectors = transaction.multisigInfo?.rejectorKeys() else {
            assertionFailure()
            return
        }

        let descriptionText = "You are about to create an on-chain rejection transaction. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: rejectors,
                                              descriptionText: descriptionText) { [weak self] keyInfo in
            guard let `self` = self else { return }
            self.dismiss(animated: true) {
                if let info = keyInfo {
                    self.rejectTransaction(info)
                }
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        openInSafari(App.configuration.help.payForCancellationURL)
    }

    private func rejectTransaction(_ keyInfo: KeyInfo) {
        self.keyInfo = keyInfo

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(rejectionTransaction, keyInfo: keyInfo)
                rejectAndCloseController(signature: signature.hexadecimal)
            } catch {
                App.shared.snackbar.show(message: "Failed to Reject transaction")
            }

        case .walletConnect:
            rejectWithWalletConnect(rejectionTransaction, keyInfo: keyInfo)

        case .ledgerNanoX:
            let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "reject"],
                                                      title: "Reject Transaction",
                                                      showsCloseButton: true)
            vc.delegate = self
            present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }

    private func rejectWithWalletConnect(_ transaction: Transaction, keyInfo: KeyInfo) {
        guard presentedViewController == nil else { return }

        let pendingConfirmationVC = WCPendingConfirmationViewController()
        pendingConfirmationVC.modalPresentationStyle = .popover
        pendingConfirmationVC.onClose = { [unowned self] in
            endLoading()
        }
        present(pendingConfirmationVC, animated: false)

        WalletConnectClientController.shared.sign(transaction: transaction) {
            [weak self] weakSignature in

            DispatchQueue.main.async {
                // dismiss pending confirmation view controller overlay
                pendingConfirmationVC.dismiss(animated: true, completion: nil)
            }

            guard let signature = weakSignature else {
                DispatchQueue.main.async {
                    self?.endLoading()
                    App.shared.snackbar.show(error: GSError.CouldNotSignWithWalletConnect())
                }
                return
            }

            self?.rejectAndCloseController(signature: signature)
        }

        WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
    }

    private func startLoading() {
        loadingView.isHidden = false
        contentContainerView.isHidden = true
    }

    private func endLoading() {
        loadingView.isHidden = true
        contentContainerView.isHidden = false
    }

    private func rejectAndCloseController(signature: String) {
        guard let keyInfo = keyInfo else { return }
        startLoading()
        _ = App.shared.clientGatewayService.asyncProposeTransaction(
            transaction: rejectionTransaction,
            sender: AddressString(keyInfo.address),
            signature: signature,
            chainId: safe.chain!.id!,
            completion: { result in
                // NOTE: sometimes the data of the transaction list is not
                // updated right away, we'll give a moment for the backend
                // to catch up before finishing with this request.
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                    switch result {
                    case .failure(let error):
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }

                        App.shared.snackbar.show(error: GSError.error(description: "Failed to Reject transaction",
                                                                      error: error))
                    case .success(_):
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)

                        switch keyInfo.keyType {
                        case .deviceGenerated, .deviceImported:
                            Tracker.trackEvent(.transactionDetailsTransactionRejected)
                        case .walletConnect:
                            Tracker.trackEvent(.transactionDetailsTxRejectedWC)
                        case .ledgerNanoX:
                            Tracker.trackEvent(.transactionDetailsTxRejectedLedgerNanoX)
                        }

                        App.shared.snackbar.show(message: "Rejection successfully submitted")
                        self?.navigationController?.popToRootViewController(animated: true)
                    }

                    self?.endLoading()
                }
            })
    }
}

extension RejectionConfirmationViewController: SelectLedgerDeviceDelegate {
    func selectLedgerDeviceViewController(_ controller: SelectLedgerDeviceViewController,
                                          didSelectDevice deviceId: UUID,
                                          bluetoothController: BluetoothController) {
        guard let safeTxHash = rejectionTransaction.safeTxHash?.description,
              let keyInfo = keyInfo, keyInfo.keyType == .ledgerNanoX,
              let metadata = keyInfo.metadata,
              let ledgerKeyMetadata = KeyInfo.LedgerKeyMetadata.from(data: metadata) else { return }

        let pendingConfirmationVC = LedgerPendingConfirmationViewController(ledgerHash: rejectionTransaction.hardwareWalletHash)
        pendingConfirmationVC.modalPresentationStyle = .popover
        pendingConfirmationVC.onClose = { [weak self] in
            self?.ledgerController = nil
            self?.endLoading()
            controller.reloadData()
        }

        // present Ledger Pending Confirmation overlay
        controller.present(pendingConfirmationVC, animated: true)
        ledgerController = LedgerController(bluetoothController: bluetoothController)
        ledgerController!.sign(safeTxHash: safeTxHash,
                               deviceId: deviceId,
                               path: ledgerKeyMetadata.path) { [weak self] signature in
            // dismiss Ledger Pending Confirmation overlay
            controller.presentedViewController?.dismiss(animated: true, completion: nil)
            guard let signature = signature else {
                App.shared.snackbar.show(message: "The operation was canceled on the Ledger device.")
                controller.reloadData()
                return
            }
            // dismiss Select Ledger Device screen and reject
            self?.presentedViewController?.dismiss(animated: false, completion: nil)
            self?.rejectAndCloseController(signature: signature)
        }
    }
}
