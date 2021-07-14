//
//  EditOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditOwnerKeyViewController: UIViewController {
    private var keyInfo: KeyInfo!
    private var name: String!
    private var saveButton: UIBarButtonItem!
    @IBOutlet private weak var textField: GNOTextField!

    convenience init(keyInfo: KeyInfo) {
        self.init()
        self.keyInfo = keyInfo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(keyInfo != nil, "Developer error: expect to have a key")

        navigationItem.title = "Edit Key Name"

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton

        textField.textField.becomeFirstResponder()
        textField.textField.text = keyInfo.name
        textField.textField.addTarget(self, action: #selector(validateName), for: .editingChanged)

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.editOwnerKey)
    }

    @objc private func didTapSaveButton() {
        OwnerKeyController.edit(keyInfo: keyInfo, name: name)
        navigationController?.popViewController(animated: true)
    }

    @objc fileprivate func validateName() {
        saveButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }

        name = text
        saveButton.isEnabled = true
    }
}
