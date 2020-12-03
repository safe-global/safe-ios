//
//  AddressInfoViewWithTitle.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressInfoViewWithTitle: UINibView {
    var onDisclosureButtonAction: (() -> Void)?

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var titleTopConstraint: NSLayoutConstraint!

    private let titleTopSpace: CGFloat = 16

    override func commonInit() {
        super.commonInit()
        titleLabel.setStyle(.headline)
        addressInfoView.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
        addressInfoView.onDisclosureButtonAction = action
    }

    func setAddressInfo(_ addressInfo: AddressInfo, title: String?) {
        titleLabel.text = title
        titleTopConstraint.constant = title == nil ? 0 : titleTopSpace
        addressInfoView.setAddressInfo(addressInfo)
    }

    func setDetailImage(_ image: UIImage, tintColor: UIColor = .gnoHold) {
        addressInfoView.setDetailImage(image, tintColor: tintColor)
    }

    private func action() {
        onDisclosureButtonAction?()
    }
}
