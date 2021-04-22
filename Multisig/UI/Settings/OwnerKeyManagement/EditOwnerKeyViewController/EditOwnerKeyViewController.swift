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

        navigationItem.title = "Edit Owner Key"

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton

        textField.textField.becomeFirstResponder()
        textField.textField.text = keyInfo.name
        textField.textField.addTarget(self, action: #selector(validateName), for: .editingChanged)

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.editOwnerKey)
    }

    @objc private func didTapSaveButton() {
        PrivateKeyController.edit(keyInfo: keyInfo, name: name)
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

    @IBAction func removeButtonTouched(_ sender: Any) {
        remove(key: keyInfo)
    }

    private func remove(key: KeyInfo) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
            DispatchQueue.main.async {
                PrivateKeyController.remove(keyInfo: key)
                navigationController?.popViewController(animated: true)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}
