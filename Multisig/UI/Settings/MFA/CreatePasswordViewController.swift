//
//  CreatePasswordViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/10/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreatePasswordViewController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var passwordInputField: PasswordInputField!
    @IBOutlet private weak var confirmPasswordField: PasswordInputField!

    @IBOutlet weak var titleLabel: UILabel!
    private var keyboardBehavior: KeyboardAvoidingBehavior!
    var onDone: (String) -> Void = { _ in }

    var password: String?
    var passwordConfirmation: String?

    convenience init(onDone: @escaping (String) -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.onDone = onDone
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create password"

        titleLabel.setStyle(.body)
        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)
        createButton.setText("Set password", .filled)

        passwordInputField.onTextBeginEditing = { [weak self] in
            self?.keyboardBehavior.activeTextField = self?.passwordInputField.textField
        }

        confirmPasswordField.onTextBeginEditing = { [weak self] in
            self?.keyboardBehavior.activeTextField = self?.confirmPasswordField.textField
        }

        passwordInputField.onTextChanged = { [weak self] password in
            // TODO: Validate password
            return (PasswordInputField.State.empty, "")
        }

        confirmPasswordField.onTextChanged = { [weak self] password in
            self?.passwordConfirmation = password
            // TODO: Validate password
            return (PasswordInputField.State.empty, "")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenCreatePassword)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @IBAction private func createButtonTouched(_ sender: Any) {
        onDone("")
    }
}
