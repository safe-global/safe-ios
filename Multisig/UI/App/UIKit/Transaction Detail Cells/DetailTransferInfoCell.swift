//
//  DetailTransferInfoCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailTransferInfoCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!
    private var tokenInfoView: TokenInfoView!
    private var addressInfoView: AddressInfoView!
    private var arrowView: DetailArrowPiece!

    override func awakeFromNib() {
        super.awakeFromNib()
        tokenInfoView = TokenInfoView(frame: stackView.bounds)
        addressInfoView = AddressInfoView(frame: stackView.bounds)
        arrowView = DetailArrowPiece(frame: stackView.bounds)

        // Because we created the views programmatically, we set the
        // heights in code:
        NSLayoutConstraint.activate([
            tokenInfoView.heightAnchor.constraint(equalToConstant: 44),
            addressInfoView.heightAnchor.constraint(equalToConstant: 44),
            arrowView.heightAnchor.constraint(equalToConstant: 24)
        ])

        setOutgoing(true)
    }

    func setAddress(_ address: Address, label: String?) {
        addressInfoView.setAddress(address, label: label)
    }

    func setToken(value: Int256, decimals: Int, symbol: String, icon: UIImage, detail: String?) {
        // need formatter for token format
        let color = value > 0 ? UIColor.gnoHold : .gnoDarkBlue
        tokenInfoView.setText("\(value) \(symbol)", style: GNOTextStyle.body.color(color))
        tokenInfoView.setImage(icon)
        tokenInfoView.setDetail(detail)
    }

    func setOutgoing(_ isOutgoing: Bool) {
        var views: [UIView] = [tokenInfoView, arrowView, addressInfoView]
        if isOutgoing {
            views.reverse()
        }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

}
