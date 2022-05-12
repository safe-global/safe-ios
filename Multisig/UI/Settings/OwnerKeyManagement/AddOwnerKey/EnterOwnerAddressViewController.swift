//
//  EnterOwnerAddressViewController.swift
//  Multisig
//
//  Created by Vitaly on 10.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterOwnerAddressViewController: UIViewController {

    @IBOutlet weak var addressField: AddressField!
    @IBOutlet weak var continueButton: UIButton!

    private var stepLabel: UILabel!

    var chain: Chain!

    var stepNumber: Int = 1
    var maxSteps: Int = 3

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

    private func didTapAddressField() {

        let picker = SelectAddressViewController(chain: chain, presenter: self) { [weak self] address in

            guard let `self` = self else { return }

            self.address = address
            self.continueButton.isEnabled = true

            let (resolvedName, _) = NamingPolicy.name(
                for: address,
                info: nil,
                chainId: self.chain.id!)

            self.addressField.setAddress(address)
            if resolvedName != nil {
                //TODO show other screen

            } else {


                let enterNameVC = EnterOwnerNameViewController()
                //enterNameVC.trackingEvent = .enterKeyName
                enterNameVC.address = address
                enterNameVC.prefix = self.chain.shortName
                enterNameVC.completion = { [unowned self] name in
                   // keyParameters.keyName = name
                   // importKey()
                }
                self.show(enterNameVC, sender: self)            }
        }

        if let popoverPresentationController = picker.popoverPresentationController {
            popoverPresentationController.sourceView = addressField
        }
        present(picker, animated: true, completion: nil)
    }

    @IBAction func didTapContinue(_ sender: Any) {
        
    }
}
