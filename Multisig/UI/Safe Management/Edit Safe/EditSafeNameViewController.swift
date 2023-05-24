//
//  EditSafeNameViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/6/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditSafeNameViewController: UIViewController {
    var name: String!
    var completion: (String) -> Void = { _ in }

    private var saveButton: UIBarButtonItem!
    @IBOutlet private weak var textField: GNOTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Edit Safe Account Name"

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton

        textField.setPlaceholder("Enter Safe Account name")
        textField.textField.becomeFirstResponder()
        textField.textField.text = name
        textField.textField.addTarget(self, action: #selector(validateName), for: .editingChanged)

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.settingsSafeEditName)
    }

    @objc private func didTapSaveButton() {
        completion(name)
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
