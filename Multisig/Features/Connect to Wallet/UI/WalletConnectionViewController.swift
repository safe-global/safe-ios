//
//  WalletConnectionViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WalletConnectionViewController: UIViewController, WebConnectionObserver {
    
    @IBOutlet weak var walletImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    var onSuccess: (_ connection: WebConnection) -> Void = { _ in }
    var onCancel: () -> Void = {}
    
    private var wallet: WCAppRegistryEntry!
    private var chain: Chain!
    
    private var connection: WebConnection!

    convenience init(wallet: WCAppRegistryEntry, chain: Chain) {
        self.init(nibName: nil, bundle: nil)
        self.wallet = wallet
        self.chain = chain
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholder = UIImage(named: "ico-wallet-placeholder")
        walletImage.setImage(
            url: wallet.imageMediumUrl,
            placeholder: placeholder,
            failedImage: placeholder
        )
        titleLabel.setStyle(.primary)
        titleLabel.text = "Connecting to \(wallet.name)..."
        cancelButton.setText("Cancel", .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //TODO: add tracking here
        guard connection == nil else { return }
        do {
            connection = try WebConnectionController.shared.connect(wallet: wallet, chainId: chain.id.flatMap(Int.init))
            WebConnectionController.shared.attach(observer: self, to: connection)

            if let link = wallet.connectLink(from: connection.connectionURL) {
                print("WC: Opening", link.absoluteString)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    UIApplication.shared.open(link, options: [:], completionHandler: nil)
                }
            } else {
                App.shared.snackbar.show(message: "Failed to open the wallet. Please choose a different one.")
                WebConnectionController.shared.userDidDisconnect(connection)
            }
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
            onCancel()
        }
    }
    
    func didUpdate(connection: WebConnection) {
        switch connection.status {
        case .opened:
            self.onSuccess(connection)
        case .final:
            // show failed to connect, close screen
            self.onCancel()
        default:
            // do nothing
            break
        }
    }
    
    deinit {
        WebConnectionController.shared.detach(observer: self)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.onCancel()
    }
}
