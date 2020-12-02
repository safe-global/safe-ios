//
//  ImportedKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportedKeyCell: UITableViewCell {
    @IBOutlet private weak var addressWithTitleView: AddressInfoView!
    var onRemove: (() -> Void)?

    static let rowHeight: CGFloat = 68

    @IBAction func removeKey() {
        onRemove?()
    }

    func setAddressInfo(_ addressInfo: AddressInfo) {
        addressWithTitleView.setAddressInfo(addressInfo)
    }
}
