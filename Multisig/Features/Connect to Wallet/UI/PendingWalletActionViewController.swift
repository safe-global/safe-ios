//
//  PendingWalletActionViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class PendingWalletActionViewController: ContainerViewController, UIAdaptivePresentationControllerDelegate, WebConnectionObserver {
    
    @IBOutlet weak var walletImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var contentView: UIView!

    var onCancel: () -> Void = {}
    
    var wallet: WCAppRegistryEntry?
    var chain: Chain!
    var keyInfo: KeyInfo!
    var connection: WebConnection!
    var timer: Timer?
    var requestTimeout: TimeInterval = 120

    var walletName: String {
        wallet?.name ?? connection?.remotePeer?.name ?? "wallet"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let keyInfo = keyInfo, connection == nil {
            connection = WebConnectionController.shared.walletConnection(keyInfo: keyInfo).first
        }
        
        let placeholder = UIImage(named: "ico-wallet-placeholder")
        walletImage.setImage(
            url: wallet?.imageMediumUrl,
            placeholder: placeholder,
            failedImage: placeholder
        )
        titleLabel.setStyle(.title2)
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
        doCancel()
    }

    func didUpdate(connection: WebConnection) {
        self.connection = connection
        if connection.status == .final {
            if let string = connection.lastError {
                App.shared.snackbar.show(message: string)
            }
            doCancel()
        }
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        main()
    }

    func main() {
        let connections = WebConnectionController.shared.walletConnection(keyInfo: keyInfo)
        if let connection = connections.first {
            self.connection = connection
            sendRequest()
        } else {
            connect { [weak self] connection in
                guard let self = self else { return }
                self.connection = connection
                if connection != nil {
                    self.sendRequest()
                } else {
                    self.doCancel()
                }
            }
        }
    }

    func connect(completion: @escaping (WebConnection?) -> ()) {
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wallet, chain: chain, keyInfo: keyInfo)

        walletConnectionVC.onSuccess = { connection in
            completion(connection)
        }
        walletConnectionVC.onCancel = {
            completion(nil)
        }

        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: wallet != nil)
        present(vc, animated: true)
    }

    func sendRequest() {
        // to override
        guard checkNetwork() else {
            let walletName = keyInfo?.displayName ?? connection.remotePeer?.name ?? wallet?.name ?? ""
            App.shared.snackbar.show(message: "Please change \(walletName) wallet network to \(chain.name!)")
            doCancel()
            return
        }
        guard let connection = connection else { return }

        WebConnectionController.shared.detach(observer: self)
        WebConnectionController.shared.attach(observer: self, to: connection)

        scheduleTimeout()

        doRequest()

        openWallet()
    }

    func checkNetwork() -> Bool {
        guard let connection = connection,
              let chainId = connection.chainId,
              String(chainId) == self.chain.id else { return false }

        return true
    }

    func scheduleTimeout() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: requestTimeout, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.onCancel()
        })
    }

    func openWallet() {
        guard let connection = self.connection else {
            assertionFailure("Expected to have connection")
            return
        }

        let navigationLink: URL?

        if let wallet = wallet, connection.status == .opened {
            navigationLink = wallet.navigateLink(from: connection.connectionURL)
        } else if let wallet = wallet {
            navigationLink = wallet.connectLink(from: connection.connectionURL)
        } else {
            // TODO: use connection's deeplink as second to last resort, otherwise use wc:
            navigationLink = nil
        }

        if let link = navigationLink {
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
    
    func doRequest() {
        // to override
    }

    func doCancel() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
}
