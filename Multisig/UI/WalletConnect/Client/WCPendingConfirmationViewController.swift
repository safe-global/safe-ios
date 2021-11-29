//
//  WCPendingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class WCPendingConfirmationViewController: UIViewController {
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    var headerText = "Pending Confirmation"
    var keyInfo: KeyInfo!

    var transaction: Transaction?
    var message: String?
    var delegateObject: AddressTimestamp?

    var onClose: (() -> Void)?
    var completion: ((String) -> Void)?

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(_ transaction: Transaction, keyInfo: KeyInfo, title: String? = nil) {
        self.init(keyInfo, title: title)
        self.transaction = transaction
    }

    convenience init(request: SignRequest, delegateObject: AddressTimestamp) {
        self.init(request.signer, title: request.title)
        self.delegateObject = delegateObject
    }

    convenience init(_ keyInfo: KeyInfo, title: String? = nil) {
        assert(keyInfo.keyType == .walletConnect)
        self.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        if let headerText = title {
            self.headerText = headerText
        }

        self.keyInfo = keyInfo
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // round top corners
        bottomView.layer.cornerRadius = 8
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        headerLabel.text = headerText
        headerLabel.setStyle(.headline)
        activityIndicator.startAnimating()
        descriptionLabel.setStyle(.callout)
        cancelButton.setText("Cancel", .plain)

        modalTransitionStyle = .crossDissolve
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose?()
    }
    
    private func close() {
        dismiss(animated: true, completion: nil)
    }

    func sign() {
        assert(keyInfo.keyType == .walletConnect)
        if let transaction = transaction {
            WalletConnectClientController.shared.sign(transaction: transaction) { [weak self] signature in
                self?.handle(signature: signature)
            }
        } else if let message = message {
            WalletConnectClientController.shared.sign(message: message) { [weak self] signature in
                self?.handle(signature: signature)
            }
        } else if let delegateObject = delegateObject {
            WalletConnectClientController.shared.sign(delegateObject: delegateObject) { [weak self] signature in
                self?.handle(signature: signature)
            }
        } else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            WalletConnectClientController.openWalletIfInstalled(keyInfo: self.keyInfo)
        }
    }

    private func handle(signature: String?) {
        DispatchQueue.main.async {
            guard let signature = signature else {
                App.shared.snackbar.show(error: GSError.CouldNotSignWithWalletConnect())
                self.dismiss(animated: true, completion: nil)

                return
            }

            self.completion?(signature)
        }
    }
}
