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

        readMoreLabel.hyperLinkLabel("Advanced users can create a non-empty (useful) transaction with the same nonce (in the web interface only). Learn more in this article: ", linkText: "Why do I need to pay for rejecting a transaction?")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.transactionDetailsRejectionConfirmation)
    }

    @IBAction func rejectButtonTouched(_ sender: Any) {
        if App.shared.auth.isPasscodeSet {
            let vc = EnterPasscodeViewController()
            let nav = UINavigationController(rootViewController: vc)
            vc.completion = { [weak self, weak nav] success in
                if success {
                    self?.rejectTransaction()
                }
                nav?.dismiss(animated: true, completion: nil)
            }
            present(nav, animated: true, completion: nil)
        } else {
            rejectTransaction()
        }
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        openInSafari(App.configuration.help.payForCancellationURL)
    }

    private func rejectTransaction() {
        startLoading()
        do {
            let safeAddress = try Safe.getSelected()!.addressValue
            let tx = Transaction.rejectionTransaction(safeAddress: safeAddress, nonce: transaction.multisigInfo!.nonce)
            let signature = try SafeTransactionSigner().sign(tx, by: safeAddress)
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
