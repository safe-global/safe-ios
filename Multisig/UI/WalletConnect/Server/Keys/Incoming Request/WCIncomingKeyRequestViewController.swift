//
//  WCIncomingKeyRequestViewController.swift
//  WCIncomingKeyRequestViewController
//
//  Created by Andrey Scherbovich on 13.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import BigInt

class WCIncomingKeyRequestViewController: UIViewController {
    @IBOutlet private weak var safeAddressInfoView: AddressInfoView!
    @IBOutlet private weak var safeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!

    private var safeAddress: Address!
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
        if App.shared.auth.isPasscodeSet && AppSettings.passcodeOptions.contains(.useForConfirmation) {
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
            let vc = SelectLedgerDeviceViewController(trackingParameters: ["action" : "wc_key_incoming_sign"],
                                                      title: "Sign Transaction",
                                                      showsCloseButton: true)
            vc.delegate = self
            present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }

    convenience init(safeAddress: Address,
                     keyInfo: KeyInfo,
                     message: String) {
        self.init()
        self.safeAddress = safeAddress
        self.keyInfo = keyInfo
        self.message = message
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        safeLabel.setStyle(.headline)
        safeAddressInfoView.setAddress(safeAddress)
        safeAddressInfoView.setDetailImage(nil)
        titleLabel.setStyle(.caption1)
        detailsLabel.setStyle(.primary)
        detailsLabel.text = message

        rejectButton.setText("Reject", .filledError)
        confirmButton.setText("Confirm", .filled)
    }
}

extension WCIncomingKeyRequestViewController: SelectLedgerDeviceDelegate {
    func selectLedgerDeviceViewController(_ controller: SelectLedgerDeviceViewController,
                                          didSelectDevice deviceId: UUID,
                                          bluetoothController: BluetoothController) {
        guard let keyInfo = keyInfo, keyInfo.keyType == .ledgerNanoX,
              let metadata = keyInfo.metadata,
              let ledgerKeyMetadata = KeyInfo.LedgerKeyMetadata.from(data: metadata) else { return }

        let pendingConfirmationVC = LedgerPendingConfirmationViewController()
        pendingConfirmationVC.modalPresentationStyle = .popover
        pendingConfirmationVC.onClose = { [weak self] in
            self?.ledgerController = nil
        }

        // dismiss Select Ledger Device screen and presend Ledger Pending Confirmation overlay
        controller.dismiss(animated: true)
        present(pendingConfirmationVC, animated: false)
        ledgerController = LedgerController(bluetoothController: bluetoothController)
        ledgerController!.sign(messageHash: message,
                               deviceId: deviceId,
                               path: ledgerKeyMetadata.path) { [weak self] signature in
            // dismiss Ledger Pending Confirmation overlay
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
            guard let signature = signature else {
                let alert = UIAlertController.ledgerAlert()
                self?.present(alert, animated: true)
                return
            }

            // substract 4 from the v part of signature
            var sig = BigInt(signature, radix: 16)!
            sig -= 4
            self?.onSign?(String(sig, radix: 16))
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true, completion: nil)
                App.shared.snackbar.show(message: "Signed successfully")
            }
        }
    }
}
