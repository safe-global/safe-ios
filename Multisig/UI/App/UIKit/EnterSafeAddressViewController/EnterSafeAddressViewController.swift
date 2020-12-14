//
//  EnterSafeAddressViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterSafeAddressViewController: UIViewController {
    var websiteURL = App.configuration.services.webAppURL
    var address: Address? { addressField?.address }

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var addressField: AddressField!
    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var openWebsiteButton: UIButton!

    private var nextButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Load Safe Multisig"
        navigationItem.rightBarButtonItem = nextButton
        headerLabel.setStyle(.headline)
        actionLabel.setStyle(.body)
        addressField.setPlaceholderText("Enter Safe address")
        nextButton.isEnabled = false
        openWebsiteButton.setText(websiteURL.absoluteString, .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.safeAddAddress)
    }

    @IBAction private func didTapOpenWebsiteButton(_ sender: Any) {
        openInSafari(websiteURL)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        // next to the enter name
    }

    private func didTapAddressField() {
        // show the alert sheet
    }

    // scanner view controller did scan
    //     didEnterText(...)

    // scanner view controller did cancel
    //      nothing

    // didSelectPasteFromClipboard
    //     didEnterText(...)

    // did selecte enter ens
    //      open in modal? or go to "next" screen

    // on ENS name entered
    //     didEnterText(...)

    private func didEnterText(_ text: String?) {
        // show loading state when networking / async in progress
        // enable / disable Next button before and after validation

        // validate that the text is address
        // and that there's no such safe already
        // and there exists safe at that address
        // and its mastercopy is supported one

        // automatically go to the next screen when the address is valid
    }

}
