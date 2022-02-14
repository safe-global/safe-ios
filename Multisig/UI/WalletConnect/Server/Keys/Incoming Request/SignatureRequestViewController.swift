//
//  WCIncomingKeyRequestViewController.swift
//  WCIncomingKeyRequestViewController
//
//  Created by Andrey Scherbovich on 13.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import BigInt
import WalletConnectSwift

class SignatureRequestViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var signerAddressView: TitledMiniPieceView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var urlLabel: UILabel!

    private var dAppMeta: Session.ClientMeta!
    private var keyInfo: KeyInfo!
    private var message: String!
    private var chain: Chain!

    var onReject: (() -> Void)?
    var onSign: ((String) -> Void)?

    @IBAction func reject(_ sender: Any) {
        onReject?()
        dismiss(animated: true, completion: nil)
        Tracker.trackEvent(.desktopPairingSignRequestRejected)
    }

    @IBAction func confirm(_ sender: Any) {
        if App.shared.auth.isPasscodeSetAndAvailable &&
            AppSettings.passcodeOptions.contains(.useForConfirmation) &&
            [.deviceImported, .deviceGenerated].contains(keyInfo.keyType) {

            let vc = EnterPasscodeViewController()
            vc.passcodeCompletion = { [weak self] success in
                if success {
                    self?.sign()
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            show(vc, sender: self)
        } else {
            sign()
        }
    }

    private func sign() {
        guard let hash = try? HashString(hex: message) else {
            onReject?()
            DispatchQueue.main.async { [unowned self] in
                self.dismiss(animated: true, completion: nil)
                App.shared.snackbar.show(message: "Signing arbitrary messages is not supported. The dApp should send a valid hash.")
            }
            return
        }

        switch keyInfo.keyType {

        case .deviceImported, .deviceGenerated:
            DispatchQueue.global().async { [unowned self] in
                do {
                    let signature = try SafeTransactionSigner().sign(hash: hash, keyInfo: keyInfo)
                    onSign?(signature.hexadecimal)
                    DispatchQueue.main.async {
                        dismiss(animated: true, completion: nil)
                        App.shared.snackbar.show(message: "Signed successfully")
                    }
                    Tracker.trackEvent(.dpSignRequestConfirmedPhoneKey)
                } catch {
                    DispatchQueue.main.async {
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Could not sign message.", error: error))
                    }
                }
            }

        case .walletConnect:
            preconditionFailure("Developer error")
        case .ledgerNanoX:
            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "wc_key_incoming_sign"],
                                      signer: keyInfo,
                                      hexToSign: hash.description)
            let vc = LedgerSignerViewController(request: request)

            present(vc, animated: true, completion: nil)

            vc.completion = { [weak self] signature in
                // subtracting 4 from the v component of the signature in order to convert it to the
                // gnosis safe signature format
                var sig = BigInt(signature, radix: 16)!
                sig -= 4
                self?.onSign?(String(sig, radix: 16))
                App.shared.snackbar.show(message: "Signed successfully")
                Tracker.trackEvent(.dpSignRequestConfirmedLedger)
            }
        }
    }

    convenience init(dAppMeta: Session.ClientMeta,
                     keyInfo: KeyInfo,
                     message: String,
                     chain: Chain) {
        self.init()
        self.dAppMeta = dAppMeta
        self.keyInfo = keyInfo
        self.message = message
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dappImageView.kf.setImage(with: dAppMeta.icons.first, placeholder: UIImage(named: "ico-empty-circle"))
        dappNameLabel.setStyle(.primary)
        dappNameLabel.text = dAppMeta.name
        urlLabel.setStyle(.tertiary)
        urlLabel.text = dAppMeta.url.host

        titleLabel.setStyle(.secondary)
        detailsLabel.setStyle(.primary)
        detailsLabel.text = message

        rejectButton.setText("Reject", .filledError)
        confirmButton.setText("Confirm", .filled)
        navigationItem.title = "Signature request"


        signerAddressView.setContent(loadingView())
        signerAddressView.setTitle("Sign with")

        loadAccountBalance()
    }

    func loadAccountBalance() {
        let balanceLoader = DefaultAccountBalanceLoader(chain: chain)

        let task = balanceLoader.loadBalances(for: [keyInfo]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                // if request cancelled, do nothing, don't call completion.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }

                self.display(balance: AccountBalanceUIModel(displayAmount: "", isEnabled: true))

            case .success(let balances):
                guard let balance = balances.first else {
                    self.display(balance: AccountBalanceUIModel(displayAmount: "", isEnabled: true))
                    return
                }
                self.display(balance: balance)
            }
        }
    }

    private func display(balance: AccountBalanceUIModel) {
        let content = MiniAccountAndBalancePiece()
        let model = MiniAccountInfoUIModel(
            prefix: self.chain.shortName,
            address: keyInfo.address,
            label: keyInfo.name,
            imageUri: nil,
            badge: nil,
            balance: balance.displayAmount
        )

        content.setModel(model)
        signerAddressView.setContent(content)
    }

    func loadingView() -> UIView {
        let skeleton = UILabel()
        skeleton.textAlignment = .right
        skeleton.isSkeletonable = true
        skeleton.skeletonTextLineHeight = .fixed(25)
        skeleton.showSkeleton(delay: 0.2)
        return skeleton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.desktopPairingSignRequest)
    }

    override func closeModal() {
        reject(self)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {

    }
    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        reject(self)
    }
}
