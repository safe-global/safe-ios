//
//  WCPendingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class WCPendingConfirmationViewController: UIViewController {
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    private var headerText = "Pending Confirmation"
    private var keyInfo: KeyInfo!

    private var transaction: Transaction?
    private var message: String?
    private var clientTransaction: Client.Transaction?

    var onClose: (() -> Void)?

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(_ transaction: Transaction, keyInfo: KeyInfo, title: String? = nil) {
        self.init(keyInfo, title: title)
        self.transaction = transaction
    }

    convenience init(_ transaction: Client.Transaction, keyInfo: KeyInfo, title: String? = nil) {
        self.init(keyInfo, title: title)
        self.clientTransaction = transaction
    }

    convenience init(_ message: String, keyInfo: KeyInfo, title: String? = nil) {
        self.init(keyInfo, title: title)
        self.message = message
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

    func sign(completion: ((String) -> Void)?) {
        if let transaction = transaction {
            WalletConnectClientController.shared.sign(transaction: transaction) { [weak self] signature in
                self?.handleSignResponse(signature: signature, completion: completion)
            }
        } else if let message = message {
            WalletConnectClientController.shared.sign(message: message) { [weak self] signature in
                self?.handleSignResponse(signature: signature, completion: completion)
            }
        } else if let clientTransaction = clientTransaction {
            WalletConnectClientController.shared.sign(transaction: clientTransaction) { [weak self] signature in
                self?.handleSignResponse(signature: signature, completion: completion)
            }
        } else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            WalletConnectClientController.openWalletIfInstalled(keyInfo: self.keyInfo)
        }
    }

    func execute(ecdsaConfirmations: [SCGModels.Confirmation], confirmationsRequired: UInt64, authenticatedRpcUrl: URL, completion: (() -> Void)?) {
        guard let transaction = transaction else { return }
        WalletConnectClientController.shared.execute(
            transaction: transaction,
            confirmations: ecdsaConfirmations,
            confirmationsRequired: confirmationsRequired,
            rpcURL: authenticatedRpcUrl,
            onSend: { [weak self] result in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    switch result {
                    case .success(_):
                        WalletConnectClientController.openWalletIfInstalled(keyInfo: self.keyInfo)
                    case .failure(let error):
                        let localizedError = (error as? DetailedLocalizedError) ?? GSError.error(
                            description: "Failed to send transaction to wallet", error: error)
                        App.shared.snackbar.show(error: localizedError)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            },
            onResult: { [weak self] result in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    switch result {
                    case .success():
                        App.shared.snackbar.show(message: "Transaction submitted. You can check the transaction status in your wallet.")
                        self.dismiss(animated: true, completion: nil)
                        completion?()
                    case .failure(let error):
                        let localizedError = (error as? DetailedLocalizedError) ?? GSError.error(
                            description: "Failed to execute transaction", error: error)
                        App.shared.snackbar.show(error: localizedError)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            })
    }

    private func handleSignResponse(signature: String?, completion: ((String) -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            guard let signature = signature else {
                App.shared.snackbar.show(error: GSError.CouldNotSignWithWalletConnect())
                return
            }
            
            self?.dismiss(animated: true, completion: nil)
            completion?(signature)
        }
    }
}
