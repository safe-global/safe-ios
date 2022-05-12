//
//  EnterOwnerAddressViewController.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterOwnerAddressViewController: UIViewController {

    var completion: (Address, String) -> Void = { _, _ in }

    @IBOutlet weak var addressField: AddressField!
    @IBOutlet weak var continueButton: UIButton!

    private var stepLabel: UILabel!

    private var chain: Chain!

    private let stepNumber: Int = 1
    private let maxSteps: Int = 3

    private var address: Address?

    override func viewDidLoad() {
        super.viewDidLoad()

        chain = try! Safe.getSelected()!.chain!

        title = "Add owner"

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        addressField.setPlaceholderText("Enter address")
        addressField.onTap = { [weak self] in self?.didTapAddressField() }

        continueButton.setText("Continue", .filled)
        continueButton.isEnabled = address != nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addOwnerSelectAddress)
    }

    private func didTapAddressField() {

        let picker = SelectAddressViewController(chain: chain, presenter: self) { [weak self] address in

            guard let `self` = self else { return }

            self.addressField.setAddress(address)
            self.address = address
            self.continueButton.isEnabled = true

            let (resolvedName, _) = NamingPolicy.name(
                for: address,
                info: nil,
                chainId: self.chain.id!)

            if resolvedName == nil {
                self.showEnterOwnerName()
            }
        }

        picker.onError = { [weak self] error, text in

            guard let `self` = self else { return }

            self.handleError(error: error, text: text)
        }

        if let popoverPresentationController = picker.popoverPresentationController {
            popoverPresentationController.sourceView = addressField
        }
        present(picker, animated: true, completion: nil)
    }

    private func showEnterOwnerName() {
        let enterNameVC = EnterOwnerNameViewController()
        enterNameVC.address = address
        enterNameVC.prefix = self.chain.shortName
        enterNameVC.completion = { [unowned self] address, name in
            self.completion(address, name)
        }
        self.show(enterNameVC, sender: self)
    }

    private func handleError(error: Error, text: String?) {
        let message = GSError.error(description: "Can’t use this address", error: error)
        addressField.setInputText(text)
        addressField.setError(message)
        address = nil
        continueButton.isEnabled = false
    }

    @IBAction func didTapContinue(_ sender: Any) {
        showEnterOwnerName()
    }
}
