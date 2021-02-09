//
//  AddressInfoView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIViewController {
    @objc func didTapAddressInfoDetails(_ sender: AddressInfoView) {
        if let address = sender.address {
            openInSafari(Safe.browserURL(address: address.checksummed))
        }
    }
}

class AddressInfoView: UINibView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private var detailButton: UIButton!

    private(set) var address: Address!
    private(set) var label: String?

    var copyEnabled: Bool {
        get { !copyButton.isHidden }
        set { copyButton.isHidden = !newValue }
    }

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headline)
        textLabel.setStyle(.headline)
        addressLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
        setTitle(nil)
    }

    func setTitle(_ text: String?) {
        titleLabel.text = text
        titleLabel.isHidden = text == nil
    }

    func setAddress(_ address: Address, label: String?, imageUri: URL?, showIdenticon: Bool = true) {
        self.address = address
        self.label = label

        if let label = label {
            textLabel.isHidden = false
            textLabel.text = label
            addressLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
            addressLabel.text = self.address.ellipsized()
        } else {
            textLabel.isHidden = true
            addressLabel.attributedText = self.address.highlighted
        }

        addressLabel.textAlignment = showIdenticon ? .left : .center
        if showIdenticon {
            let placeholder = BlockiesImageProvider(seed: address.hexadecimal, width: 36, height: 36).roundImage()!
            identiconView.kf.setImage(with: imageUri, placeholder: placeholder)
        }
    }

    func setDetailImage(_ image: UIImage?, tintColor: UIColor = .gnoHold) {
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
