//
//  DetailTwoAccountsCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailTwoAccountsCell: UITableViewCell {
    @IBOutlet private weak var addressInfoViewWithTitleOne: AddressInfoViewWithTitle!
    @IBOutlet private weak var addressInfoViewWithTitleTwo: AddressInfoViewWithTitle!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoViewWithTitleOne.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
        addressInfoViewWithTitleTwo.setDetailImage(#imageLiteral(resourceName: "ico-browse-address"))
    }

    func setAccount(at index: Int, addressInfo: AddressInfo, title: String?, onViewDetails: @escaping () -> Void) {
        switch index {
        case 0:
            addressInfoViewWithTitleOne.setAddressInfo(addressInfo, title: title)
            addressInfoViewWithTitleOne.onDisclosureButtonAction = onViewDetails
        case 1:
            addressInfoViewWithTitleTwo.setAddressInfo(addressInfo, title: title)
            addressInfoViewWithTitleTwo.onDisclosureButtonAction = onViewDetails
        default:
            preconditionFailure("`index` is out of bounds")
        }
    }
}
