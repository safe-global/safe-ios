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

class WCIncomingKeyRequestViewController: UIViewController {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var signerAddressInfoView: AddressInfoView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!

    private var dAppMeta: Session.ClientMeta!
    private var keyInfo: KeyInfo!
    private var message: String!
    private var ledgerController: LedgerController?

    var onReject: (() -> Void)?
    var onSign: ((String) -> Void)?

    @IBAction func reject(_ sender: Any) {
        onReject?()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func confirm(_ sender: Any) {
        if App.shared.auth.isPasscodeSet &&
            AppSettings.passcodeOptions.contains(.useForConfirmation) &&
            keyInfo.keyType != .ledgerNanoX {

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
            }
        }
    }

    convenience init(dAppMeta: Session.ClientMeta,
                     keyInfo: KeyInfo,
                     message: String) {
        self.init()
        self.dAppMeta = dAppMeta
        self.keyInfo = keyInfo
        self.message = message
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dappImageView.kf.setImage(with: dAppMeta.icons.first, placeholder: UIImage(named: "ico-empty-circle"))
        dappNameLabel.setStyle(.headline)
        dappNameLabel.text = dAppMeta.name
        signerAddressInfoView.setAddress(keyInfo.address, label: keyInfo.name)
        signerAddressInfoView.setDetailImage(nil)
        titleLabel.setStyle(.caption1)
        detailsLabel.setStyle(.primary)
        detailsLabel.text = message

        rejectButton.setText("Reject", .filledError)
        confirmButton.setText("Confirm", .filled)
    }
}
