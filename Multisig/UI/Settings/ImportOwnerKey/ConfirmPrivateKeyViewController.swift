//
//  ConfirmPrivateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3

class ConfirmPrivateKeyViewController: UIViewController {
    @IBOutlet private weak var identiconImageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!

    private var privateKey: Data!
    private var address: Address!
    private var isDrivedFromSeedPhrase: Bool = true

    private lazy var importButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Import",
            style: .done,
            target: self,
            action: #selector(didTapImport))
        return button
    }()

    convenience init(privateKey: Data, isDrivedFromSeedPhrase: Bool = true) {
        self.init()
        self.privateKey = privateKey
        let address = try! EthereumPrivateKey(hexPrivateKey: privateKey.toHexString()).address
        self.address = Address(address, index: 0)
        self.isDrivedFromSeedPhrase = isDrivedFromSeedPhrase
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Owner Key"
        navigationItem.rightBarButtonItem = importButton
        identiconImageView.setAddress(address.hexadecimal)
        addressLabel.attributedText = address.highlighted
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerConfirmPrivateKey)
    }

    @objc func didTapImport() {
        guard PrivateKeyController.importKey(privateKey, isDrivedFromSeedPhrase: isDrivedFromSeedPhrase) else { return }
        if App.shared.auth.isPasscodeSet || AppSettings.passcodeWasSetAtLeastOnce {
            App.shared.snackbar.show(message: "Owner key successfully imported")
            dismiss(animated: true, completion: nil)
        } else {
            let vc = CreatePasscodeViewController()
            vc.navigationItem.hidesBackButton = true
            vc.hidesHeadline = false
            show(vc, sender: self)
        }
    }
}
