//
//  EnterSafeNameViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterSafeNameViewController: UIViewController {
    var address: Address!
    var name: String?
    var completion: () -> Void = { }

    private var nextButton: UIBarButtonItem!
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textField: GNOTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(address != nil, "Developer error: expect to have an address")
        identiconView.setAddress(address.hexadecimal)
        addressLabel.attributedText = address.highlighted
        descriptionLabel.setStyle(.body)

        textField.setPlaceholder("Enter name")
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()

        navigationItem.title = "Load Safe Multisig"

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton))
        nextButton.isEnabled = false
        navigationItem.rightBarButtonItem = nextButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.safeAddName)
    }

    @objc private func didTapNextButton() {
        guard let name = name, let address = address else { return }
        Safe.create(address: address.checksummed, name: name)
        if let _ = App.shared.settings.signingKeyAddress {
            completion()
        } else if AppSettings.hasShownImportKeyOnboarding() {
            // Here we need to show Enter seedphase screen
        } else {
            let vc = SafeLoadedViewController()
            vc.completion = completion
            show(vc, sender: self)
            AppSettings.showImportKeyOnboarding()
        }
    }

    fileprivate func validateName() {
        nextButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        self.name = text
        nextButton.isEnabled = true
    }
}

extension EnterSafeNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}
