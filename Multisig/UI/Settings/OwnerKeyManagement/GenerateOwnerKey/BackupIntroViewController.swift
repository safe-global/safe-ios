//
//  BackupIntroViewController.swift
//  Multisig
//
//  Created by Vitaly on 11.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupIntroViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tipsView: TipsView!
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Back up key"
        
        titleLabel.setStyle(.primary)
        messageLabel.setStyle(.secondary)
        tipsView.setContent(
            title: "Security tips",
            tips: [
                "Never share your seed phrase with anyone!",
                "Write it down on paper or keep it in a vault.",
                "Store it in a secret place or multiple places that you trust."
            ]
        )
        
        backupButton.setText("Back up manually", .filled)
        cancelButton.setText("Not now", .plain)
    }
}
