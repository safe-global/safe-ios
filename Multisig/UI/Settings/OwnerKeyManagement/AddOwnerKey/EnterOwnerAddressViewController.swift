//
//  EnterOwnerAddressViewController.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterOwnerAddressViewController: UIViewController {

    var completion: ((Address, String?) -> Void)?

    @IBOutlet weak var addressField: AddressField!
    @IBOutlet weak var continueButton: UIButton!

    private var stepLabel: UILabel!

    var safe: Safe!

    var stepNumber: Int = 1
    var maxSteps: Int = 3
    var trackingEvent: TrackingEvent?

    private var address: Address?
    private var name: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(safe?.chain != nil)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        addressField.setPlaceholderText("Enter address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        continueButton.setText("Continue", .filled)
        continueButton.isEnabled = address != nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    private func didTapAddressField() {
        let picker = SelectAddressViewController(chain: safe.chain!, presenter: self) { [weak self] address in
            guard let self = self else { return }

            self.clearErrors()

            self.address = address
            self.continueButton.isEnabled = true

            let (resolvedName, _) = NamingPolicy.name(
                for: address,
                info: nil,
                chainId: self.safe.chain!.id!)

            self.addressField.setAddress(address, label: resolvedName, prefix: self.safe.chain?.shortName)
            self.name = resolvedName

            self.checkEqualToSafe()
            self.checkExisting()
        }

        picker.onError = { [weak self] error, text in
            self?.handleError(error: error, text: text)
        }

        if let popoverPresentationController = picker.popoverPresentationController {
            popoverPresentationController.sourceView = addressField
        }
        present(picker, animated: true, completion: nil)
    }

    private func clearErrors() {
        addressField.setError(nil)
    }

    private func checkEqualToSafe() {
        guard safe.addressValue == address else { return }
        handleError(error: "Cannot use Safe itself as owner.", text: address?.checksummed)
    }

    private func checkExisting() {
        guard let owners = safe.ownersInfo?.map(\.address), let address = address else { return }
        if owners.contains(address) {
            handleError(error: "Owner with this address already exists", text: address.checksummed)
        }
    }

    private func handleError(error: Error, text: String?) {
        let message = GSError.error(description: "Can’t use this address", error: error)
        addressField.setInputText(text)
        addressField.setError(message)
        address = nil
        continueButton.isEnabled = false
    }

    @IBAction func didTapContinue(_ sender: Any) {
        assert(address != nil)
        completion?(address!, name)
    }
}
