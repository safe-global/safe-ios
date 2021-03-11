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
            if let info = keyInfo {
                self.rejectTransaction(info)
            }
            self.dismiss(animated: true)
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        openInSafari(App.configuration.help.payForCancellationURL)
    }

    private func rejectTransaction(_ keyInfo: KeyInfo) {
        startLoading()
        do {
            let safeAddress = try Safe.getSelected()!.addressValue
            let tx = Transaction.rejectionTransaction(safeAddress: safeAddress, nonce: transaction.multisigInfo!.nonce)
            let signature = try SafeTransactionSigner().sign(tx, by: safeAddress, keyInfo: keyInfo)
            _ = App.shared.clientGatewayService.propose(transaction: tx,
                                                        safeAddress: safeAddress,
                                                        sender: signature.signer.checksummed,
                                                        signature: signature.hexadecimal,
                                                        completion: { [weak self] result in

                // NOTE: sometimes the data of the transaction list is not
                // updated right away, we'll give a moment for the backend
                // to catch up before finishing with this request.
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                    if case Result.success(_) = result {
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        Tracker.shared.track(event: TrackingEvent.transactionDetailsTransactionRejected)
                        App.shared.snackbar.show(message: "Rejection successfully submitted")
                        self?.navigationController?.popToRootViewController(animated: true)
                    } else {
                        App.shared.snackbar.show(message: "Failed to Reject transaction")
                    }
                    self?.endLoading()
                }
            })
        } catch {
            App.shared.snackbar.show(message: "Failed to Reject transaction")
        }
    }

    func startLoading() {
        loadingView.isHidden = false
        contentContainerView.isHidden = true
    }

    func endLoading() {
        loadingView.isHidden = true
        contentContainerView.isHidden = false
    }
}
