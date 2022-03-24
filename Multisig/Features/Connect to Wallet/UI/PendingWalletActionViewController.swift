//
//  PendingWalletActionViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class PendingWalletActionViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var walletImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    var onCancel: () -> Void = {}
    
    var wallet: WCAppRegistryEntry!
    var chain: Chain!
    var keyInfo: KeyInfo!
    var connection: WebConnection!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholder = UIImage(named: "ico-wallet-placeholder")
        walletImage.setImage(
            url: wallet.imageMediumUrl,
            placeholder: placeholder,
            failedImage: placeholder
        )
        titleLabel.setStyle(.primary)
        cancelButton.setText("Cancel", .plain)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    override func closeModal() {
        didTapCancel(self)
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        didTapCancel(self)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel()
    }
    
    func connect(completion: @escaping (WebConnection?) -> ()) {
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain)

        walletConnectionVC.onSuccess = { [weak walletConnectionVC, weak self] connection in
            walletConnectionVC?.dismiss(animated: true) {
                guard let self = self else { return }
                guard connection.accounts.contains(self.keyInfo.address) else {
                    App.shared.snackbar.show(error: GSError.WCConnectedKeyMissingAddress())
                    return
                }

                if OwnerKeyController.updateKey(connection: connection, wallet: self.wallet) {
                    App.shared.snackbar.show(message: "Key connected successfully")
                }

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
    
    func checkNetwork() -> Bool {
        guard let connection = connection,
              let chainId = connection.chainId,
              String(chainId) == self.chain.id else { return false }

        return true
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
}
