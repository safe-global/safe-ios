//
//  SelectKeyTypeViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectKeyTypeViewController: UIViewController {
    @IBOutlet private weak var storeOnDeviceButtonView: BigImageWithTextButtonView!
    @IBOutlet private weak var walletConnectKeyButtonView: BigImageWithTextButtonView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Signing Key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))

        storeOnDeviceButtonView.set(image: UIImage(named: "ico-app-settings")!)
        storeOnDeviceButtonView.set(text: "Store key on device")
        storeOnDeviceButtonView.onSecect = { [unowned self] in
            let onboardingVC = OnboardingImportOwnerKeyViewController()
            self.navigationController?.pushViewController(onboardingVC, animated: true)
        }

        walletConnectKeyButtonView.set(image: UIImage(named: "wc-button")!)
        walletConnectKeyButtonView.set(text: "Connect key via WalletConnect")
        walletConnectKeyButtonView.onSecect = {
            let onboardingVC = OnboardingConnectOwnerKeyViewController()
            self.navigationController?.pushViewController(onboardingVC, animated: true)
        }
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}
