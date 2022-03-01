//
//  SelectAddressViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectAddressViewController: UIAlertController {

    var onSuccess: (Address) -> Void = { _ in }

    convenience init(onSuccess: @escaping (Address) -> Void) {
        self.init(title: nil, message: nil, preferredStyle: .actionSheet)
        self.onSuccess = onSuccess
        addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: handleClipboard(_:)))
        addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: handleQRCode(_:)))
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }

    func handleClipboard(_ action: UIAlertAction) {
        let text = Pasteboard.string
        handleText(text)
    }

    func handleQRCode(_ action: UIAlertAction) {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { [unowned self] value in
            do {
                try self.validate(value)
                return .success(value)
            } catch {
                return .failure(error)
            }
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        self.present(vc, animated: true, completion: nil)
    }

    func handleAddressBook(_ action: UIAlertAction) {

    }

    func handleExistingAccount(_ action: UIAlertAction) {

    }

    func handleNewAccount(_ action: UIAlertAction) {

    }

    func handleSafe(_ action: UIAlertAction) {

    }

    // params:
        // chain - when passed, then validate against that chain
        // otherwise, accept any chain and return as a result.

    @discardableResult
    func validate(_ text: String?) throws -> String {
        // can be:
            // - address
            // - transaction request url
            // - wallet-connect url

        guard var text = text else {
            throw SelectAddressError.empty
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            throw SelectAddressError.empty
        }

        // address part:
            // lowercase hex
            // uppercase hex
            // uppercase all hex (0X)
            // eip-55 checksummed

        // string part:
            // eip-3770 shortname prefix
            // eip-681 transaction request url
                // function = transfer | transferFrom
                    // params = to | from, to --> (to)
                // to --> to
            // caip-10 chain-agnostic account id with namespace
            // eip-137 ens domain name --> resolve to address
            // unstoppable domain name

        return text
    }

    func handleText(_ text: String?) {
        // validate
    }
}

extension SelectAddressViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        handleText(code)
        dismiss(animated: true, completion: nil)
    }
}

struct SelectAddressError: CustomNSError {
    static var errorDomain: String { "io.gnosis.safe.createSafeModel" }
    var errorCode: Int
    var message: String
    var cause: Error? = nil

    var errorUserInfo: [String : Any] {
        var result: [String: Any] = [NSLocalizedDescriptionKey: message]
        if let cause = cause {
            result[NSUnderlyingErrorKey]  = cause
        }
        return result
    }
}

extension SelectAddressError {
    static let empty = SelectAddressError(errorCode: -1, message: "Address should not be empty")
}
