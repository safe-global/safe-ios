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
    var timer: Timer?
    var requestTimeout: TimeInterval = 120

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
