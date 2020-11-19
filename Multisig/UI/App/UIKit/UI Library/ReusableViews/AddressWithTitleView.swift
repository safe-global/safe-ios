//
//  AddressWithTitleView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressWithTitleView: UINibView {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var button: UIButton!

    private var style: Style = .nameAndAddress
    private (set) var address: Address!

    enum Style {
        case nameAndAddress
        case address
    }

    override func commonInit() {
        super.commonInit()
        textLabel.setStyle(.headline)
        detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    func setStyle(_ value: Style) {
        style = value
        update()
    }

    func setAddress(_ value: Address) {
        address = value
        identiconView.setAddress(value.hexadecimal)
        update()
    }

    func setName(_ value: String) {
        textLabel.text = value
    }

    private func update() {
        switch style {
        case .nameAndAddress:
            textLabel.isHidden = false
            detailLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
            detailLabel.text = address.ellipsized()
        case .address:
            textLabel.isHidden = true
            detailLabel.attributedText = address.highlighted
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    // visual reaction for user touches
    @objc private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @objc private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }
}
