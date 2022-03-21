//
//  SendTransactionToWalletViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift

class SendTransactionToWalletViewController: PendingWalletActionViewController {

    var transaction: Client.Transaction!
    var keyInfo: KeyInfo!
    var chain: Chain!

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

        let connections = WebConnectionController.shared.walletConnection(keyInfo: keyInfo)
        if let connection = connections.first {
            self.connection = connection
            if checkNetwork() {
                send()
            } else {
                changeNetwork(connection: connection)
            }
        } else {
            connect { [ unowned self] connection in
                self.connection = connection
                if let connection = connection {
                    if self.checkNetwork() {
                        self.send()
                    } else {
                        self.changeNetwork(connection: connection)
                    }
                } else {
                    onCancel()
                }
            }
        }
    }

    func checkNetwork() -> Bool {
        guard let connection = connection,
              let chainId = connection.chainId,
              String(chainId) == self.chain.id else { return false }

        return true
    }

    func connect(completion: @escaping (WebConnection?) -> ()) {
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain)

        walletConnectionVC.onSuccess = { [weak walletConnectionVC] connection in
            walletConnectionVC?.dismiss(animated: true) {
                //TODO: updating key info

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

    func changeNetwork(connection: WebConnection) {

    }

    func send() {
        guard let connection = connection else { return }

        let webConnectionController = WebConnectionController()
        webConnectionController.sendTransaction(connection: connection, transaction: transaction) { [ unowned self ] result in
            switch result {
            case .failure(let error):
                App.shared.snackbar.show(message: error.localizedDescription)
                onCancel()
            case .success(let data):
                self.onSuccess?(data)
            }
        }
    }

    override func didTapCancel(_ sender: Any) {
        onCancel()
    }

    // connection status update

    // connection network updated

    // no response after <timeout>
}
