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
    @IBOutlet weak var qrCodeImageView: UIImageView!

    private var code: String!

    static func create(code: String) -> WalletConnectQRCodeViewController {
        let controller = WalletConnectQRCodeViewController(nibName: "WalletConnectQRCodeViewController", bundle: Bundle.main)
        controller.code = code
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WalletConnect"
        header.setStyle(.headline)

        let data = code.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        qrCodeImageView.image = UIImage(ciImage: filter.outputImage!.transformed(by: transform))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.walletConnectKeyQR)
    }
}
