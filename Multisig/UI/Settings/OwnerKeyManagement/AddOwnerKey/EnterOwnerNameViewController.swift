//
//  EnterOwnerNameViewController.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterOwnerNameViewController: UIViewController {

    var prefix: String?
    var address: Address!
    var name: String?
    var completion: (String) -> Void = { _ in }

    @IBOutlet weak var identiconView: IdenticonView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var textField: GNOTextField!
    @IBOutlet weak var disclaimerLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!

    private var stepLabel: UILabel!

    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    var stepNumber: Int = 1
    var maxSteps: Int = 3
    
    var trackingEvent: TrackingEvent?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add owner"

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        identiconView.set(address: address)
        let prefixString = prefixString()
        addressLabel.attributedText = (prefixString + address.checksummed).highlight(prefix: prefixString.count + 6)

        textField.setPlaceholder("Enter name")
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()
        if let name = name {
            textField.textField.text = name
        }

        disclaimerLabel.setStyle(.secondary)

        continueButton.setText("Continue", .filled)

        validateName()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    private func validateName() {
        continueButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            self.name = nil
            return
        }
        self.name = text
        continueButton.isEnabled = true
    }

    private func prefixString() -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }

    @IBAction func didTapContinue(_ sender: Any) {
        completion(name!)
    }
}

extension EnterOwnerNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}
