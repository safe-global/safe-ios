//
//  WalletConnectQRCodeViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 16.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class WalletConnectQRCodeViewController: UIViewController {
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var qrCodeView: QRCodeView!
    @IBOutlet weak var copyButton: UIButton!

    private var code: String!

    static func create(code: String) -> WalletConnectQRCodeViewController {
        let controller = WalletConnectQRCodeViewController(nibName: nil, bundle: nil)
        controller.code = code
        return controller
    }

    @IBAction func copyToClipboard(_ sender: Any) {
        Pasteboard.string = code
        App.shared.snackbar.show(message: "Copied to clipboard")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WalletConnect"
        header.setStyle(.headline)
        copyButton.setText("Copy to clipboard", .plain)

        qrCodeView.value = code
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectKeyQR)
    }
}
