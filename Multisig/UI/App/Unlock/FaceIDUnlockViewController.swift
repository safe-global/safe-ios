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
        navigationController?.isNavigationBarHidden = true
        label.setStyle(.slogan)
        unlockButton.setText("Unlock", .filled)
        unlockDataStore()
    }

    fileprivate func unlockDataStore() {
        do {
            try App.shared.securityCenter.unlockDataStore()
            self.completion(true, false)
        } catch {
            //TODO: error handling
        }
    }

    @IBAction func didTapUnlock(_ sender: Any) {
        unlockDataStore()
    }
}
