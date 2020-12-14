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

    func setAccounts(accounts: [(address: Address, label: String?, title: String?)]) {
        let views = accounts.map { data -> AddressInfoView in
            let v = AddressInfoView(frame: contentView.bounds)
            v.setTitle(data.title)
            v.setAddress(data.address, label: data.label)
            return v
        }
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }
}
