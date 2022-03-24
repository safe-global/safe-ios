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

    convenience init(_ transaction: Client.Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
        self.keyInfo = keyInfo
        self.clientTransaction = transaction
        self.chain = chain
    }
    
    convenience init(_ transaction: Transaction, keyInfo: KeyInfo, chain: Chain, isRejection: Bool = false) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
        self.keyInfo = keyInfo
        self.transaction = transaction
        self.isRejection = isRejection
        self.chain = chain
    }
    
    convenience init(_ message: String, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
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
        DispatchQueue.main.async {
            switch result {
            case .failure(let error):
                App.shared.snackbar.show(message: error.localizedDescription)
                self.doCancel()
            case .success(let signature):
                self.dismiss(animated: true) {
                    self.onSuccess?(signature)
                }
            }
        }
    }
}

