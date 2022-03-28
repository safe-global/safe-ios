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

class SendTransactionToWalletViewController: PendingWalletActionViewController {

    var transaction: Client.Transaction!

    var onSuccess: ((Data) -> ())?

    convenience init(transaction: Client.Transaction, keyInfo: KeyInfo, chain: Chain) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        self.keyInfo = keyInfo
        self.transaction = transaction
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Sending transaction request to \(walletName)"
    }

    override func doRequest() {
        WebConnectionController.shared.sendTransaction(connection: connection, transaction: transaction) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                App.shared.snackbar.show(message: error.localizedDescription)
                self.doCancel()
            case .success(let data):
                self.dismiss(animated: true) {
                    self.onSuccess?(data)
                }
            }
        }
    }
}
