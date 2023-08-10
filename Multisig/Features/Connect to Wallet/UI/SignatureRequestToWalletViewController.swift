//
//  SignatureRequestToWalletViewController.swift
//  Multisig
//
//  Created by Vitaly on 24.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import WalletConnectSwift

class SignatureRequestToWalletViewController: PendingWalletActionViewController {

    private var transaction: Transaction?
    private var clientTransaction: Client.Transaction?
    private var isRejection: Bool = false
    private var message: String?

    var onSuccess: ((String) -> ())?

    // if true and the chain does not match the wallet chain then the operation will cancel.
    var requiresChainIdMatch: Bool = true

    convenience init(_ transaction: Client.Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        self.keyInfo = keyInfo
        self.clientTransaction = transaction
        self.chain = chain
    }
    
    convenience init(_ transaction: Transaction, keyInfo: KeyInfo, chain: Chain, isRejection: Bool = false) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        self.keyInfo = keyInfo
        self.transaction = transaction
        self.isRejection = isRejection
        self.chain = chain
    }
    
    convenience init(_ message: String, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        self.keyInfo = keyInfo
        self.message = message
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if transaction != nil {
            if isRejection {
                titleLabel.text = "Confirm Rejection with your owner key from \(walletName)"
            } else {
                titleLabel.text = "Confirm Transaction with your owner key from \(walletName)"
            }
        } else {
            titleLabel.text = "Approve request with your owner key from \(walletName)"
        }
    }

    override func checkNetwork() -> Bool {
        guard requiresChainIdMatch else { return true }
        return super.checkNetwork()
    }

    override func doRequest() {
        if let transaction = transaction {
            WebConnectionController.shared.wcSign(connection: connection, transaction: transaction) { [weak self] result in
                self?.handleRequestResponse(result)
            }
        } else if let message = message {
            WebConnectionController.shared.wcSign(connection: connection, message: message) { [weak self] result in
                self?.handleRequestResponse(result)
            }
        }
    }

    private func handleRequestResponse(_ result: Result<String, Error>) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                let wallet = self.connection?.remotePeer?.name
                let message = error.localizedDescription
                let errorMessage = [wallet, message].compactMap{ $0 }.joined(separator: ": ")
                App.shared.snackbar.show(message: errorMessage)
                self.doCancel()
            case .success(let signature):
                self.dismiss(animated: true) {
                    self.onSuccess?(signature)
                }
            }
        }
    }
}

