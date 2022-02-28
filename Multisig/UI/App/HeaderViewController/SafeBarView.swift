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

    private(set) var prefix: String?
    private(set) var address: Address!
    private(set) var isDeploying: Bool = false

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headline)
        detailLabel.setStyle(.tertiary)
        accessoryLabel.setStyle(.tertiary)
        setReadOnly(false)
        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(displayAddress),
                                               name: .chainSettingsChanged,
                                               object: nil)
        
    }

    func setAddress(_ value: Address, prefix: String?, isDepolying: Bool = false) {
        self.address = value
        self.prefix = prefix
        self.isDeploying = isDepolying
        identiconView.setAddress(value.hexadecimal)
        displayAddress()
    }

    func setName(_ value: String) {
        textLabel.text = value
    }

    func setReadOnly(_ readOnly: Bool) {
        accessoryLabel.text = readOnly ? "Read-only" : nil
        accessoryLabel.isHidden = !readOnly
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
        detailLabel.text = isDeploying ? "Creating in progress..." : prefixString() + address.ellipsized()
    }

    private func prefixString() -> String {
        (AppSettings.prependingChainPrefixToAddresses && prefix != nil ? "\(prefix!):" : "" )
    }
}

