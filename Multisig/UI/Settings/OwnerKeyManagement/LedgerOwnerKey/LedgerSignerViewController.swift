//
//  LedgerSignerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

struct SignRequest {
    var title: String
    var tracking: [String: Any]
    var signer: KeyInfo
    var hexToSign: String
}

class LedgerSignerViewController: UINavigationController {
    var completion: ((String) -> Void)!
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
        vc.delegate = self
    }
}

extension LedgerSignerViewController: SelectLedgerDeviceDelegate {
    func selectLedgerDeviceViewController(
        _ controller: SelectLedgerDeviceViewController,
        didSelectDevice deviceId: UUID,
        bluetoothController: BaseBluetoothController
    ) {
        guard let data = request.signer.metadata,
              let metadata = KeyInfo.LedgerKeyMetadata.from(data: data) else { return }

        let confirmVC = LedgerPendingConfirmationViewController(
            headerText: request.title,
            bluetoothController: bluetoothController,
            hexToSign: request.hexToSign,
            deviceId: deviceId,
            derivationPath: metadata.path)

        confirmVC.modalPresentationStyle = .popover
        confirmVC.modalTransitionStyle = .crossDissolve

        present(confirmVC, animated: true)

        confirmVC.onClose = { [unowned controller] in
            controller.reloadData()
            controller.onClose?()
        }

        confirmVC.onSign = { [weak self, unowned controller] signature, errorMessage in
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
                controller.reloadData()
                return
            }

            let signatureData = Data(hex: signature)

            guard let signedOwner = Address(data: self.request.hexToSign.hexToBytes(), signature: signatureData),
                    signedOwner == self.request.signer.address else {
                App.shared.snackbar.show(error: GSError.SignerMismatch())

                // reload the devices in case we lost connection
                controller.reloadData()
                return
            }
            // got signature, dismiss the first SelectDevice screen.
            self.dismiss(animated: true, completion: nil)

            self.completion(signature)
        }
    }
}
