//
//  RejectionConfirmationViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version

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
                                         safeVersion: Version(safe.contractVersion!)!,
                                         chainId: safe.chain!.id!)
    }()
    private var safe: Safe!
    private var keyInfo: KeyInfo?
    private var ledgerController: LedgerController?
    private var keystoneSignFlow: KeystoneSignFlow!
    
    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: RejectionConfirmationViewController.self)
        self.transaction = transaction
        self.safe = try! Safe.getSelected()!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rejectionButton.setText("Reject transaction", .filledError)
        navigationItem.title = "Reject Transaction"

        createOnChainRejectionLabel.setStyle(.footnote)
        collectConfirmationsLabel.setStyle(.footnote)
        executeOnChainRejectionLabel.setStyle(.footnote)
        initialTransactionLabel.setStyle(.footnote)
        descriptionLabel.setStyle(.body)

        readMoreLabel.hyperLinkLabel("Advanced users can create a non-empty (useful) transaction with the same nonce (in the web interface only). Learn more in this article: ",
                                     prefixStyle: .body,
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
        let vc = ChooseOwnerKeyViewController(
            owners: rejectors,
            chainID: safe.chain!.id,
            header: .text(description: descriptionText)
        ) { [weak self] keyInfo in
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
        case .deviceImported, .deviceGenerated, .web3AuthGoogle, .web3AuthApple:
            Wallet.shared.sign(rejectionTransaction, keyInfo: keyInfo) { [unowned self] result in
                do {
                    let signature = try result.get()
                    rejectAndCloseController(signature: signature.hexadecimal)

                } catch {
                    App.shared.snackbar.show(message: "Failed to Reject transaction")
                }
            }

        case .walletConnect:
            rejectWithWalletConnect(rejectionTransaction, keyInfo: keyInfo)

        case .ledgerNanoX:
            let request = SignRequest(title: "Reject Transaction",
                                      tracking: ["action" : "reject"],
                                      signer: keyInfo,
                                      hexToSign: rejectionTransaction.safeTxHash.description)
            let vc = LedgerSignerViewController(request: request)
            present(vc, animated: true, completion: nil)

            vc.completion = { [weak self] signature in
                self?.rejectAndCloseController(signature: signature)
            }
            vc.onClose = { [weak self] in
                self?.endLoading()
            }
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: rejectionTransaction.safeTxHash.hash.toHexString(),
                chain: safe.chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned self] (success: Bool) in
                keystoneSignFlow = nil
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                    endLoading()
                }
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                endLoading()
                return
            }
            
            keystoneSignFlow = signFlow
            keystoneSignFlow.signCompletion = { [weak self] unmarshaledSignature in
                self?.rejectAndCloseController(signature: unmarshaledSignature.safeSignature)
            }
            present(flow: keystoneSignFlow)
        }
    }

    private func rejectWithWalletConnect(_ transaction: Transaction, keyInfo: KeyInfo) {
        guard presentedViewController == nil else { return }

        let signVC = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: safe.chain!)
        signVC.onSuccess = { [weak self] signature in
            DispatchQueue.main.async {
                self?.rejectAndCloseController(signature: signature)
            }
        }
        signVC.onCancel = { [weak self] in
            self?.endLoading()
        }
        let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
        present(vc, animated: true)
    }

    private func startLoading() {
        self.loadingView.isHidden = false
        self.contentContainerView.isHidden = true
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

                        Tracker.trackEvent(
                            .userTransactionRejected,
                            parameters: TrackingEvent.keyTypeParameters(keyInfo, parameters: ["source": "tx_details"])
                        )

                        App.shared.snackbar.show(message: "Rejection successfully submitted")
                        self?.navigationController?.popToRootViewController(animated: true)
                    }

                    self?.endLoading()
                }
            })
    }
}
