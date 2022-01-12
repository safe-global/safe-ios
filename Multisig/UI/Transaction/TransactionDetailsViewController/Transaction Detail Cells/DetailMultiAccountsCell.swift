//
//  DetailTwoAccountsCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailMultiAccountsCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!

    func setAccounts(accounts: [(address: Address,
                                 label: String?,
                                 imageUri: URL?,
                                 title: String?,
                                 browseURL: URL?,
                                 prefix: String?)]) {
        let views = accounts.map { data -> AddressInfoView in
            let v = AddressInfoView(frame: contentView.bounds)
            v.setTitle(data.title)
            v.setAddress(data.address,
                         label: data.label,
                         imageUri: data.imageUri,
                         browseURL: data.browseURL,
                         prefix: data.prefix)
            return v
        }
        setViews(views)
    }

    func setViews(_ views: [UIView]) {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }
}
