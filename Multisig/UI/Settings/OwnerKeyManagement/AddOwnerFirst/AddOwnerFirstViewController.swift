//
//  AddOwnerFirstViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 15.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerFirstViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addOwnerKeyButton: UIButton!

    var onSuccess: (() -> ())?

    var descriptionText: String = "To start sending funds import at least one owner key. Keys are used to confirm transactions."

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Owner Key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(CloseModal.closeModal))

        titleLabel.setStyle(.headline)
        messageLabel.setStyle(.secondary)
        messageLabel.text = descriptionText
        addOwnerKeyButton.setText("Add owner key", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsTransferAddOwner)
    }
    
    @IBAction func addOwnerKeyClicked(_ sender: Any) {
        let vc = AddOwnerKeyViewController(showsCloseButton: false) { [unowned self] in
            self.onSuccess?()
        }
        show(vc, sender: self)
        Tracker.trackEvent(.assetTransferAddOwnerClicked)
    }
}
