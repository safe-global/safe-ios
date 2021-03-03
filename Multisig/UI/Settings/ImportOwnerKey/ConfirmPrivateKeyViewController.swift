//
//  ConfirmPrivateKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ConfirmPrivateKeyViewController: UIViewController {
    @IBOutlet private weak var identiconImageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!

    private var privateKey: PrivateKey!
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

    convenience init(privateKey data: Data, isDrivedFromSeedPhrase: Bool = true) {
        self.init()
        self.privateKey = try! PrivateKey(data: data)
        self.address = privateKey.address
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
        let success = PrivateKeyController.importKey(
            privateKey.data,
            isDrivedFromSeedPhrase: isDrivedFromSeedPhrase)
        guard success else { return }
        if App.shared.auth.isPasscodeSet {
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
