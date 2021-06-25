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

    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: RejectionConfirmationViewController.self)
        self.transaction = transaction
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
        trackEvent(.transactionDetailsRejectionConfirmation)
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
        startLoading()

        var safeAddress: Address
        do {
            safeAddress = try Safe.getSelected()!.addressValue
        } catch {
            App.shared.snackbar.show(message: "Failed to Reject transaction")
            return
        }
        var tx = Transaction.rejectionTransaction(safeAddress: safeAddress, nonce: transaction.multisigInfo!.nonce)
        tx.safe = AddressString(safeAddress)

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(tx, keyInfo: keyInfo)
                rejectAndCloseController(transaction: tx,
                                         sender: AddressString(keyInfo.address),
                                         signature: signature.hexadecimal,
                                         keyType: keyInfo.keyType)
            } catch {
                App.shared.snackbar.show(message: "Failed to Reject transaction")
            }

        case .walletConnect:
            WalletConnectClientController.shared.sign(transaction: tx, from: self) { [unowned self] signature in
                rejectAndCloseController(transaction: tx,
                                         sender: AddressString(keyInfo.address),
                                         signature: signature,
                                         keyType: keyInfo.keyType)
            }

            WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
        }
    }

    private func startLoading() {
        loadingView.isHidden = false
        contentContainerView.isHidden = true
    }

    private func endLoading() {
        loadingView.isHidden = true
        contentContainerView.isHidden = false
    }

    private func rejectAndCloseController(transaction: Transaction,
                                          sender: AddressString,
                                          signature: String,
                                          keyType: KeyType) {
        _ = App.shared.clientGatewayService.asyncProposeTransaction(
            transaction: transaction,
            sender: sender,
            signature: signature,
            completion: { [weak self] result in
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

                        switch keyType {
                        case .deviceGenerated, .deviceImported:
                            Tracker.shared.track(event: TrackingEvent.transactionDetailsTransactionRejected)
                        case .walletConnect:
                            Tracker.shared.track(event: TrackingEvent.transactionDetailsTxRejectedWC)
                        }

                        App.shared.snackbar.show(message: "Rejection successfully submitted")
                        self?.navigationController?.popToRootViewController(animated: true)
                    }

                    self?.endLoading()
                }
            })
    }
}
