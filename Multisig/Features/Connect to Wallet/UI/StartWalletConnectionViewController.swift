//
//  StartWalletConnectionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class StartWalletConnectionViewController: PendingWalletActionViewController {
    var onSuccess: (_ connection: WebConnection) -> Void = { _ in }

    var qrCodeController: QRCodeShareViewController!

    convenience init(wallet: WCAppRegistryEntry?, chain: Chain, keyInfo: KeyInfo? = nil) {
        self.init(namedClass: PendingWalletActionViewController.self)
        self.wallet = wallet
        self.chain = chain
        self.keyInfo = keyInfo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let wallet = wallet {
            titleLabel.text = "Connecting to \(wallet.name)..."
        } else {
            titleLabel.text = "Scan QR code in your wallet"
            qrCodeController = QRCodeShareViewController()
            viewControllers = [qrCodeController]
            activityIndicator.isHidden = true
        }
    }

    override func main() {
        //TODO: add tracking here
        guard connection == nil else { return }
        do {
            connection = try WebConnectionController.shared.connect(wallet: wallet, chainId: chain.id.flatMap(Int.init))
            WebConnectionController.shared.attach(observer: self, to: connection)
            if wallet != nil {
                openWallet()
            } else {
                displayChild(at: 0, in: contentView)
                qrCodeController.value = connection.connectionURL.absoluteString
            }
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
            doCancel()
        }
    }

    override func didUpdate(connection: WebConnection) {
        self.connection = connection
        switch connection.status {
        case .opened:
            guard checkCorrectAccount() else { return }
            guard checkCorrectChain() else { return }

            if let keyInfo = keyInfo, OwnerKeyController.updateKey(keyInfo, connection: connection, wallet: wallet) {
                App.shared.snackbar.show(message: "Key connected successfully")
            }

            self.dismiss(animated: true) { [weak self] in
                self?.onSuccess(connection)
            }
        case .final:
            if let string = connection.lastError {
                App.shared.snackbar.show(message: string)
            }
            doCancel()
        default:
            // do nothing
            break
        }
    }

    func checkCorrectAccount() -> Bool {
        if let keyInfo = keyInfo, !connection.accounts.contains(keyInfo.address) {
            App.shared.snackbar.show(message: "Unexpected address. Please connnect to account \(keyInfo.address.ellipsized()).")
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        } else if keyInfo == nil, let account = connection.accounts.first, let existing = (try? KeyInfo.firstKey(address: account)) {
            let name = existing.displayName.prefix(30)
            App.shared.snackbar.show(message: "Address '\(account.ellipsized())' already exists with name '\(name)'. Please connect another account.")
            WebConnectionController.shared.userDidDisconnect(connection)
            return false
        } else {
            return true
        }
    }

    func checkCorrectChain() -> Bool {
        // always succeeds, but shows warning message in case networks are different.

        if let chain = chain,
           let connectedChainId = connection.chainId,
           let selectedChainId = chain.id,
           String(connectedChainId) != selectedChainId {
            let connectedChain = Chain.by(String(connectedChainId))
            let selectedName = chain.name ?? "Chain Id \(selectedChainId)"
            let connectedName = connectedChain?.name ?? "Chain Id \(connectedChainId)"
            let icon = UIImage(systemName: "exclamationmark.triangle.fill")!.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            App.shared.snackbar.show(
                message: "Selected Safe's network '\(selectedName)' is different from the network in the wallet: '\(connectedName)'.",
                icon: SnackbarViewController.IconSource.image(icon)
            )
        }
        return true
    }

    override func didTapCancel(_ sender: Any) {
        if let connection = connection {
            WebConnectionController.shared.userDidCancel(connection)
        } else {
            doCancel()
        }
    }
}
