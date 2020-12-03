//
//  DetailAccountAndTextCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailAccountAndTextCell: UITableViewCell {
    var onViewDetails: (() -> Void)?

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textTitleLabel: UILabel!
    @IBOutlet private weak var textDetailsLabel: UILabel!

    private let titleTopSpace: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        textTitleLabel.setStyle(.body)
        textDetailsLabel.setStyle(GNOTextStyle.body.color(.gnoDarkGrey))
        addressInfoView.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
        addressInfoView.onDisclosureButtonAction = viewDetails
    }

    func setAccount(addressInfo: AddressInfo, title: String?) {
        titleLabel.text = title
        titleTopConstraint.constant = title == nil ? 0 : titleTopSpace
        addressInfoView.setAddressInfo(addressInfo)
    }

    func setText(title: String, details: String) {
        textTitleLabel.text = title
        textDetailsLabel.text = details
    }

    private func viewDetails() {
        onViewDetails?()
    }
}
