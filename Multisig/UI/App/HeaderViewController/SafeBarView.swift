//
//  SafeBarView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// When given:
///     - address, name: displays identicon, name, and address
///     - nothing: displays 'no safe loaded' icon and text
class SafeBarView: UINibView {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var accessoryLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var claimableAmountView: ClaimableAmountView!

    private(set) var prefix: String?
    private(set) var address: Address!
    
    override func commonInit() {
        super.commonInit()
        setReadOnly(false)
        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(displayAddress),
                                               name: .chainSettingsChanged,
                                               object: nil)
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.setStyle(.headline)
        detailLabel.setStyle(.bodyTertiary)
        accessoryLabel.setStyle(.bodyTertiary)
    }

    func setAddress(_ value: Address, prefix: String?) {
        self.address = value
        self.prefix = prefix
        identiconView.setAddress(value.hexadecimal)
        displayAddress()
    }

    func setAddress(_ value: Address, grayscale: Bool) {
        self.address = value
        if grayscale {
            identiconView.setAddressGrayscale(value.hexadecimal)
        }
        displayAddress()
    }

    func setDetail(text: String, style: GNOTextStyle = .bodyTertiary) {
        detailLabel.text = text
        detailLabel.setStyle(style)
    }

    func setName(_ value: String) {
        textLabel.text = value
    }

    func setReadOnly(_ readOnly: Bool) {
        accessoryLabel.text = readOnly ? "Read-only" : nil
        accessoryLabel.isHidden = !readOnly
    }

    func set(safeTokenClaimable: Bool) {
        claimableAmountView.isHidden = !safeTokenClaimable
    }

    // encapsulating the button's target-action API
    func set(onClaim: @escaping () -> ()) {
        claimableAmountView.onClaim = onClaim
    }

    // encapsulating the button's target-action API
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        button.removeTarget(target, action: action, for: controlEvents)
    }

    // visual reaction for user touches
    @objc private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @objc private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }

    @objc func displayAddress() {
        guard let address = address else { return }
        detailLabel.setStyle(.bodyTertiary)
        detailLabel.text = prefixString() + address.ellipsized()
    }

    private func prefixString() -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }
}

