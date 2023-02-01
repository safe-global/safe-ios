//
//  FaceIDUnlockViewController.swift
//  Multisig
//
//  Created by Vitaly on 31.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class FaceIDUnlockViewController: UIViewController {

    @IBOutlet private weak var label: UILabel!

    @IBOutlet private weak var unlockButton: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()

        label.setStyle(.body)
        unlockButton.setText("Unlock", .filled)
    }

    @IBAction func didTapUnlock(_ sender: Any) {
    }
}
