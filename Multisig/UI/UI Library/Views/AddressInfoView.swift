//
//  AddressInfoView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressInfoView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var identiconView: IdenticonView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private var detailButton: UIButton!

    private(set) var address: Address!
    private(set) var browseURL: URL?
    private(set) var prefix: String?
    private(set) var label: String?

    var copyEnabled: Bool {
        get { !copyButton.isHidden }
        set { copyButton.isHidden = !newValue }
    }

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headline)
        textLabel.setStyle(.headline)
        addressLabel.setStyle(.tertiary)
        setTitle(nil)
    }

    func setTitle(_ text: String?) {
        titleLabel.text = text
        titleLabel.isHidden = text == nil
    }

    func setAddress(_ address: Address, label: String? = nil, imageUri: URL? = nil, showIdenticon: Bool = true, badgeName: String? = nil) {
        self.address = address
        self.label = label

        if let label = label {
            textLabel.isHidden = false
            textLabel.text = label
            addressLabel.setStyle(.tertiary)
            addressLabel.text = self.address.ellipsized()
        } else {
            textLabel.isHidden = true
            addressLabel.attributedText = self.address.highlighted
        }

        addressLabel.textAlignment = showIdenticon ? .left : .center
        if showIdenticon {
            identiconView.set(address: address, imageURL: imageUri, badgeName: badgeName)
        }
        identiconView.isHidden = !showIdenticon
    }

    func setDetailImage(_ image: UIImage?, tintColor: UIColor = .button) {
        detailButton.isHidden = image == nil
        detailButton.tintColor = tintColor
        detailButton.setImage(image, for: .normal)
    }

    @IBAction private func didTapDetailButton() {
        UIApplication.shared.sendAction(#selector(UIViewController.didTapAddressInfoDetails(_:)), to: nil, from: self, for: nil)
    }

    @IBAction private func copyAddress() {
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    @IBAction private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @IBAction private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }
}

extension UIViewController {
    @objc func didTapAddressInfoDetails(_ sender: AddressInfoView) {
        if let url = sender.browseURL {
            openInSafari(url)
        }
    }
}
