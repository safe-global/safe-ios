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
    
    var onSuccess: () -> Void = {}
    var onCancel: () -> Void = {}
    
    private var wallet: WCAppRegistryEntry!
    private var chain: Chain!
    
    private var connection: WebConnection?
    
    convenience init(
        wallet: WCAppRegistryEntry,
        chain: Chain
    ) {
        self.init(nibName: nil, bundle: nil)
        self.wallet = wallet
        self.chain = chain
    }
    
    static func present(
        presenter: UIViewController,
        walletRegistryEntry: WCAppRegistryEntry,
        chain: Chain,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let walletConnectionVC = WalletConnectionViewController(
            wallet: walletRegistryEntry,
            chain: chain
        )
        walletConnectionVC.onSuccess = onSuccess
        walletConnectionVC.onCancel = onCancel
        let vc = ViewControllerFactory.modal(viewController: walletConnectionVC, halfScreen: true)
        presenter.present(vc, animated: true)
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
        
        do {
            let connection = try WebConnectionController.shared.connect(wallet: wallet, chainId: chain.id.map(Int.init))
            WebConnectionController.shared.attach(observer: self, to: connection)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
            self.onCancel()
        }
    }
    
    func didUpdate(connection: WebConnection) {
        switch connection.status {
        case .opened:
            self.onSuccess()
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
