//
//  BackupIntroViewController.swift
//  Multisig
//
//  Created by Vitaly on 11.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupIntroViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tipsView: TipsView!
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var backupCompletion: (_ backup: Bool) -> Void = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
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
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    @IBAction func didTapBackup(_ sender: Any) {
        backupCompletion(true)
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        backupCompletion(false)
    }
}
