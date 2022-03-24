//
//  SendTransactionToWalletViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import WalletConnectSwift

class SendTransactionToWalletViewController: PendingWalletActionViewController, WebConnectionObserver {

    var transaction: Client.Transaction!
    var keyInfo: KeyInfo!
    var chain: Chain!
    var timer: Timer?
    var requestTimeout: TimeInterval = 120

    var connection: WebConnection?
    var onSuccess: ((Data) -> ())?

    convenience init(transaction: Client.Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = WCAppRegistryRepository().entry(from: keyInfo.wallet!)
        self.keyInfo = keyInfo
        self.transaction = transaction
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Sending transaction request to \(wallet.name)"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendTransactionWhenConnected()
    }

    func sendTransactionWhenConnected() {
        let connections = WebConnectionController.shared.walletConnection(keyInfo: keyInfo)
        if let connection = connections.first {
            self.connection = connection
                send()
        } else {
            connect { [ unowned self] connection in
                self.connection = connection
                if connection != nil {
                    self.send()
                } else {
                    onCancel()
                }
            }
        }
    }

    func connect(completion: @escaping (WebConnection?) -> ()) {
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain, keyInfo: keyInfo)

        walletConnectionVC.onSuccess = { [weak walletConnectionVC] connection in
            walletConnectionVC?.dismiss(animated: true) {
                completion(connection)
            }
        }

        walletConnectionVC.onCancel = { [weak walletConnectionVC] in
            walletConnectionVC?.dismiss(animated: true, completion: {
                completion(nil)
            })
        }

        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: true)
        present(vc, animated: true)
    }

    func send() {
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

        WebConnectionController.shared.sendTransaction(connection: connection, transaction: transaction) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                App.shared.snackbar.show(message: error.localizedDescription)
                self.onCancel()
            case .success(let data):
                self.onSuccess?(data)
            }
        }

        openWallet(connection: connection)
    }

    func openWallet(connection: WebConnection) {
        if let link = wallet.navigateLink(from: connection.connectionURL) {
            LogService.shared.debug("WC: Opening \(link.absoluteString)")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                UIApplication.shared.open(link, options: [:]) { success in
                    if !success {
                        App.shared.snackbar.show(message: "Failed to open the wallet automatically. Please open it manually or try again.")
                    }
                }
            }
        } else {
            App.shared.snackbar.show(message: "Please open your wallet to complete this operation.")
        }
    }

    func checkNetwork() -> Bool {
        guard let connection = connection,
              let chainId = connection.chainId,
              String(chainId) == self.chain.id else { return false }

        return true
    }

    override func didTapCancel(_ sender: Any) {
        onCancel()
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    func didUpdate(connection: WebConnection) {
        if connection.status == .final {
            onCancel()
        }
    }
}
