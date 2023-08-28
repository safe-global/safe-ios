//
//  EnterSafeNameViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterAddressNameViewController: UIViewController {
    var address: Address!
    var prefix: String?
    var badgeName: String?
    var name: String?
    var trackingEvent: TrackingEvent!
    var screenTitle: String?
    var actionTitle: String!
    var placeholder: String!
    var descriptionText: String!
    var completion: (_ name: String) -> Void = { _ in }
    var trackingParameters: [String: Any]?

    private var nextButton: UIBarButtonItem!
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    @IBOutlet private weak var identiconView: IdenticonView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textField: GNOTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(address != nil, "Developer error: expect to have an address")
        assert(descriptionText?.isEmpty == false, "Developer error: expect to have a description")
        assert(actionTitle?.isEmpty == false, "Developer error: expect to have an action title")
        assert(placeholder?.isEmpty == false, "Developer error: expect to have a placeholder")
        assert(trackingEvent != nil, "Developer error: expect to have a tracking event")

        identiconView.set(address: address, badgeName: badgeName)
        let prefixString = prefixString()
        addressLabel.attributedText = (prefixString + address.checksummed).highlight(prefix: prefixString.count + 6)
        descriptionLabel.setStyle(.body)
        descriptionLabel.text = descriptionText

        textField.setPlaceholder(placeholder)
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()
        if let name = name {
            textField.textField.text = name
        }

        navigationItem.title = screenTitle

        nextButton = UIBarButtonItem(title: actionTitle, style: .done, target: self, action: #selector(didTapNextButton))
        navigationItem.rightBarButtonItem = nextButton

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(trackingEvent, parameters: trackingParameters)
    }

    @objc private func didTapNextButton() {
        guard let name = name else { return }
        completion(name)
    }

    private func validateName() {
        nextButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            self.name = nil
            return
        }
        self.name = text
        nextButton.isEnabled = true
    }

    private func prefixString() -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }
}

extension EnterAddressNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}
