//
//  LedgerSignerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeWeb3

struct SignRequest {
    var title: String
    var tracking: [String: Any]
    var signer: KeyInfo
    var payload: Payload

    enum Payload {
        case hash(String)
        case rawTx(data: Data, chainId: Int, isLegacy: Bool)
    }
}

extension SignRequest {
    init(title: String, tracking: [String: Any], signer: KeyInfo, hexToSign: String) {
        self.init(title: title, tracking: tracking, signer: signer, payload: .hash(hexToSign))
    }
}

class LedgerSignerViewController: UINavigationController {
    var completion: ((String) -> Void)!
    var txCompletion: (((v: UInt8, r: Data, s: Data)) -> Void)?

    var onClose: (() -> Void)? {
        didSet {
            if let vc = viewControllers.first as? SelectLedgerDeviceViewController {
                vc.onClose = onClose
            }
        }
    }
    private var request: SignRequest!

    convenience init(request: SignRequest) {
        assert(request.signer.keyType == .ledgerNanoX)
        let vc = SelectLedgerDeviceViewController(trackingParameters: request.tracking,
                                                  title: request.title,
                                                  showsCloseButton: true)
        self.init(rootViewController: vc)
        self.request = request
        vc.completion = { [unowned self, unowned vc] deviceId, bluetoothController in
            guard let data = request.signer.metadata,
                  let metadata = KeyInfo.LedgerKeyMetadata.from(data: data) else { return }

            let confirmVC = LedgerPendingConfirmationViewController(
                headerText: request.title,
                bluetoothController: bluetoothController,
                signRequest: request,
                deviceId: deviceId,
                derivationPath: metadata.path)

            confirmVC.modalPresentationStyle = .popover
            confirmVC.modalTransitionStyle = .crossDissolve

            present(confirmVC, animated: true)

            confirmVC.onClose = { [unowned vc] in
                vc.reloadData()
                vc.onClose?()
            }

            confirmVC.onTxSign = { [weak self, unowned vc] result in
                guard let self = self else { return }

                // dismiss Ledger Pending Confirmation overlay
                self.dismiss(animated: true, completion: nil)

                switch result {
                case .failure(let error):
                    let gsError = GSError.error(description: "The operation failed.", error: error)
                    App.shared.snackbar.show(error: gsError)

                    vc.reloadData()

                case .success(let signature):
                    // got signature, dismiss the first SelectDevice screen.
                    self.dismiss(animated: true, completion: nil)

                    self.txCompletion?(signature)
                }
            }

            confirmVC.onSign = { [weak self, unowned vc] signature, errorMessage in
                guard let self = self else { return }

                // dismiss Ledger Pending Confirmation overlay
                self.dismiss(animated: true, completion: nil)

                guard let signature = signature else {
                    // Possible reasons:
                    //  - bluetooth pairing failure
                    //  - ethereum app on the ledger device is not open
                    //  - cancelled on ledger device
                    // In these situations it is more convenient to keep the bluetooth discover open
                    // so we just show the error and reload data
                    let message = errorMessage ?? "The operation was canceled on the Ledger device."
                    App.shared.snackbar.show(message: message)

                    // reload the devices in case we lost connection
                    vc.reloadData()
                    return
                }

                // layout is <r: 35 bytes><s: 35 bytes><v: 1 byte>; v = (0 | 1) + 27 + 4
                let signatureData: Data = Data(hex: signature)
                assert(signatureData.count >= 65)
                let r = Data(Array(signatureData[0..<32]))
                let s = Data(Array(signatureData[32..<64]))
                let v = signatureData[64]

                // original message signed by Ledger has Ethereum prefix according to eth_sign
                guard case let SignRequest.Payload.hash(hexToSign) = self.request!.payload else {
                    preconditionFailure("Unexpected payload: \(self.request!.payload)")
                }
                let originalHash: Data = Data(hex: hexToSign)
                let prefix = "\u{19}Ethereum Signed Message:\n\(originalHash.count)"
                let prefixedMessage = prefix.data(using: .utf8)! + originalHash

                // recover the public key
                let pubKey = try? EthereumPublicKey.init(message: prefixedMessage.makeBytes(),
                                                         v: EthereumQuantity(quantity: BigUInt(v - 27 - 4)),
                                                         r: EthereumQuantity(r.makeBytes()),
                                                         s: EthereumQuantity(s.makeBytes()))

                // Since it's possible to sign with a key different from the one user selected in app UI in the previous
                // step, we'll check that the actual signer is the same as the selected owner.

                guard let signedOwner = pubKey?.address,
                        Address(signedOwner) == self.request.signer.address else {
                    App.shared.snackbar.show(error: GSError.SignerMismatch())

                    // reload the devices in case we lost connection
                    vc.reloadData()
                    return
                }

                // got signature, dismiss the first SelectDevice screen.
                self.dismiss(animated: true, completion: nil)

                self.completion(signature)
            }
        }
    }
}
