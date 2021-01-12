//
//  EditSafeNameViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/6/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditSafeNameViewController: UIViewController {
    var address: Address!
    var name: String?
    var completion: () -> Void = { }

    private var saveButton: UIBarButtonItem!
    @IBOutlet private weak var textField: GNOTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(address != nil, "Developer error: expect to have an address")

        navigationItem.title = "Edit Safe Name"

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton

        textField.setPlaceholder("Enter safe name")
        textField.textField.becomeFirstResponder()
        textField.textField.text = name
        textField.textField.addTarget(self, action: #selector(validateName), for: .editingChanged)

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsSafeEditName)
    }

    @objc private func didTapSaveButton() {
        guard let name = name, let address = address else { return }
        Safe.edit(address: address.checksummed, name: name)
        completion()
    }

    @objc fileprivate func validateName() {
        saveButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        self.name = text
        saveButton.isEnabled = true
    }
}
