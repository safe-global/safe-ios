//
//  FaceIDUnlockViewController.swift
//  Multisig
//
//  Created by Vitaly on 31.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class FaceIDUnlockViewController: ContainerViewController {

    @IBOutlet private weak var contentView: UIView!

    @IBOutlet private weak var unlockButton: UIButton!

    private var contentController: PrivacyProtectionScreenViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        contentController = PrivacyProtectionScreenViewController()
        viewControllers = [contentController]
        displayChild(at: 0, in: contentView)

        unlockButton.setText("Unlock", .filled)
    }

    @IBAction func didTapUnlock(_ sender: Any) {
    }
}
