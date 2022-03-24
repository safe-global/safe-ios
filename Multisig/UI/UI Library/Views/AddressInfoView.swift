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
    @IBOutlet private weak var networkLabel: UILabel!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private var detailButton: UIButton!

    @IBOutlet weak var iconHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressHeight: NSLayoutConstraint!

    static let defaultIconSize: CGFloat = 36

    private(set) var address: Address!
    private(set) var browseURL: URL?
    private(set) var prefix: String?
    private(set) var label: String?
    private(set) var copyAddressEnabled: Bool = true

    var copyEnabled: Bool {
        get { !copyButton.isHidden }
        set { copyButton.isHidden = !newValue }
    }

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headline)
        textLabel.setStyle(.headline)
        addressLabel.setStyle(.tertiary)
        addressLabel.isHidden = true
        setTitle(nil)
        networkLabel.setStyle(.tertiary)
        networkLabel.isHidden = true
        addressHeight.constant = 46

        setIconSize(Self.defaultIconSize)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(displayAddress),
                                               name: .chainSettingsChanged,
                                               object: nil)
    }

    func setIconSize(_ value: CGFloat) {
        iconWidthConstraint.constant = value
        iconHeightConstraint.constant = value
        setNeedsUpdateConstraints()
    }

    func setTitle(_ text: String?) {
        titleLabel.text = text
        titleLabel.isHidden = text == nil
    }

    /// Configures the address view
    /// - Parameters:
    ///   - address: the address for the identicon and address label
    ///   - label: the label for the address, shown above the address
    ///   - imageUri: url of an image instead of identicon
    ///   - showIdenticon: if true then the identicon (or imageUri) is shown, if false then identicon is hidden
    ///   - badgeName: name of the badge asset image
    ///   - browseURL: if not nil, then the detail button will show that would open the browser to look for this address
    ///   - prefix: chain prefix
    ///   - chain: connected chain (via WalletConnect)
    ///   - connectionStatus: WalletConnect status
    func setAddress(_ address: Address,
                    label: String? = nil,
                    imageUri: URL? = nil,
                    showIdenticon: Bool = true,
                    badgeName: String? = nil,
                    browseURL: URL? = nil,
                    prefix: String? = nil,
                    chain: Chain? = nil,
                    connectionStatus: KeyConnectionStatus? = nil
    ) {
        self.address = address
        self.browseURL = browseURL
        self.prefix = prefix
        self.label = label

        if let chain = chain {
            networkLabel.isHidden = false
            networkLabel.text = chain.name
            networkLabel.textColor = chain.textColor
            networkLabel.backgroundColor = chain.backgroundColor
        }

        if  let label = self.label {
            if connectionStatus != nil && connectionStatus! != .none {
                let attachment = NSTextAttachment()
                setConnectionStatusImage(connectionStatus: connectionStatus, attachment: attachment)
                let attachmentString = NSAttributedString(attachment: attachment)
                let labelAttributedString = NSMutableAttributedString(string: "\(label) ")
                labelAttributedString.append(attachmentString)
                textLabel.text = label
                textLabel.attributedText = labelAttributedString
            } else {
                textLabel.text = label
            }
            textLabel.isHidden = false
        } else {
            textLabel.isHidden = true
        }

        displayAddress()
        addressLabel.textAlignment = showIdenticon ? .left : .center
        if showIdenticon {
            identiconView.set(address: address, imageURL: imageUri, badgeName: badgeName)
        }
        identiconView.isHidden = !showIdenticon
        detailButton.isHidden = browseURL == nil
    }

    // show address with identicon, and show label or address ellipsized.
    func setAddressOneLine(
        _ address: Address,
        label: String? = nil,
        imageUri: URL? = nil,
        badgeName: String? = nil,
        prefix: String? = nil
    ) {
        self.address = address
        self.browseURL = nil
        self.prefix = prefix
        self.label = label

        textLabel.isHidden = false
        if let label = label {
            textLabel.text = label
        } else {
            textLabel.text = prependingPrefixString() + self.address.ellipsized()
        }
        addressLabel.isHidden = true

        identiconView.isHidden = false
        identiconView.set(address: address, imageURL: imageUri, badgeName: badgeName)

        detailButton.isHidden = browseURL == nil
    }

    @IBAction private func didTapDetailButton() {
        UIApplication.shared.sendAction(#selector(UIViewController.didTapAddressInfoDetails(_:)), to: nil, from: self, for: nil)
    }

    func setCopyAddressEnabled(_ enabled: Bool) {
        self.copyAddressEnabled = enabled
        self.copyButton.isEnabled = enabled
    }

    @IBAction private func copyAddress() {
        guard copyAddressEnabled else { return }
        Pasteboard.string = copyPrefixString() + address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    @IBAction private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @IBAction private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }

    @objc func displayAddress() {
        addressLabel.isHidden = false
        if let _ = label {
            addressLabel.text = prependingPrefixString() + self.address.ellipsized()
        } else {
            let prefixString = prependingPrefixString()
            addressLabel.attributedText = (prefixString + self.address.checksummed).highlight(prefix: prefixString.count + 6)
        }
    }

    private func copyPrefixString() -> String {
        AppSettings.copyAddressWithChainPrefix ? prefixString() : ""
    }

    private func prependingPrefixString() -> String {
        AppSettings.prependingChainPrefixToAddresses ? prefixString() : ""
    }

    private func prefixString() -> String {
        prefix != nil ? "\(prefix!):" : ""
    }

    private func setConnectionStatusImage(connectionStatus: KeyConnectionStatus?, attachment: NSTextAttachment) {
        if let connectionStatus = connectionStatus {
            switch connectionStatus {
            case .none:
                attachment.image = nil
            case .connected:
                attachment.image = UIImage(named: "ico-wc-connected")
            case .disconnected:
                attachment.image = UIImage(named: "ico-empty-circle")
            case .connectionProblem:
                attachment.image = UIImage(named: "ico-warning")
            }
        } else {
            attachment.image = nil
        }
    }
}

extension UIViewController {
    @objc func didTapAddressInfoDetails(_ sender: AddressInfoView) {
        if let url = sender.browseURL {
            openInSafari(url)
        }
    }
}

