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

class SignatureRequestToWalletViewController: PendingWalletActionViewController, WebConnectionObserver {

    private var transaction: Transaction?
    private var clientTransaction: Client.Transaction?
    private var message: String?

    var timer: Timer?
    var requestTimeout: TimeInterval = 120

    var onSuccess: ((String) -> ())?

    convenience init(_ transaction: Client.Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
        self.keyInfo = keyInfo
        self.clientTransaction = transaction
        self.chain = chain
    }
    
    convenience init(_ transaction: Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
        self.keyInfo = keyInfo
        self.transaction = transaction
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
            titleLabel.text = "Confirm Transaction with your owner key from \(wallet.name)"
        } else {
            titleLabel.text = "Approve request with your owner key from \(wallet.name)"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestSignatureWhenConnected()
    }

    func requestSignatureWhenConnected() {
        let connections = WebConnectionController.shared.walletConnection(keyInfo: keyInfo)
        if let connection = connections.first {
            self.connection = connection
                send()
        } else {
            connect { [ unowned self] connection in
                self.connection = connection
                if connection != nil {
                    self.requestSignature()
                } else {
                    onCancel()
                }
            }
        }
    }

    func requestSignature() {
        guard checkNetwork() else {
            App.shared.snackbar.show(message: "Please change wallet network to \(chain.name!)")
            return
        }
        guard let connection = connection else { return }

        WebConnectionController.shared.detach(observer: self)
        WebConnectionController.shared.attach(observer: self, to: connection)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: requestTimeout, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.onCancel()
        })

        if let transaction = transaction {
            WebConnectionController.shared.wcSign(connection: connection, transaction: transaction) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.onCancel()
                case .success(let signature):
                    self?.handleSignResponse(signature: signature, completion: onSuccess)
                }
            }
            openWallet(connection: connection)
        } else if let message = message {
            WebConnectionController.shared.wcSign(connection: connection, message: message) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.onCancel()
                case .success(let signature):
                    self?.handleSignResponse(signature: signature, completion: onSuccess)
                }
            }
        }
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

    override func didTapCancel(_ sender: Any) {
        onCancel()
    }
    
    func didUpdate(connection: WebConnection) {
        if connection.status == .final {
            onCancel()
        }
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }
}

