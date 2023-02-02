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

    var completion: (_ success: Bool, _ reset: Bool) -> Void = { _, _ in }

    override func viewDidLoad() {
        super.viewDidLoad()

        label.setStyle(.body)
        unlockButton.setText("Unlock", .filled)
    }

    @IBAction func didTapUnlock(_ sender: Any) {
        App.shared.auth.authenticateWithBiometrics { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.completion(true, false)

            case .failure(_):
                break
            }
        }
    }
}
