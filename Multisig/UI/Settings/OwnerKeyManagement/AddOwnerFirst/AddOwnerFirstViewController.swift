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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Owner Key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(CloseModal.closeModal))

        titleLabel.setStyle(.headline)
        messageLabel.setStyle(.primary)
        addOwnerKeyButton.setText("Add owner key", .filled)
    }
    
    @IBAction func addOwnerKeyClicked(_ sender: Any) {
        let vc = AddOwnerKeyViewController(showsCloseButton: false) { [unowned self] in
            self.dismiss(animated: true, completion: nil)
            self.onSuccess?()
        }
        show(vc, sender: self)
    }
}
