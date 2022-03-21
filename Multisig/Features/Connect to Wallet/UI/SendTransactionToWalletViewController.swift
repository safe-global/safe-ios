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

        // not connected
            // connect

        // if chain is not matching
            // switch chains
            // then send request

        // send the request
            // connection --> wc url
            // client tx is already there.
    }

    func connect() {
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain)
        walletConnectionVC.onSuccess = { [weak walletConnectionVC] connection in
            walletConnectionVC?.dismiss(animated: true) {
//                guard connection.accounts.contains(keyInfo.address) else {
//                    App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
//                    return
//                }

                // check connection account and connection network
            }
        }

        walletConnectionVC.onCancel = { [weak walletConnectionVC] in
            walletConnectionVC?.dismiss(animated: true, completion: { [unowned self] in
                self.didTapCancel(self)
            })
        }
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: true)
        present(vc, animated: true)
    }

    func send() {

    }

    override func didTapCancel(_ sender: Any) {
        onCancel()
    }

    // connection status update

    // connection network updated

    // user cancels request screen

    // user cancels connection screen -> cancel request.

    // response received - success

    // response received - error

    // no response after <timeout>

    var state = State.initial

    enum State {
        case initial
        case connecting
        case checkingConnection
        case pendingRequest
        case done
    }

}

// initial
// connecting
    // start connection
// checking connection
    // check that network matches
    // check that account is the keyInfo (selected account)
    // send request, start timeout timer
// pending request
    // waits for response
    // handle response.
// done

// final (connection closed)
    // cancel request. close the screen.
