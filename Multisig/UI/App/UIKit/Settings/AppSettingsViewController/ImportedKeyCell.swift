//
//  ImportedKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportedKeyCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()
        let image = UIImage(systemName: "trash")?.applyingSymbolConfiguration( .init(weight: .semibold))
        addressInfoView.setDetailImage(image, tintColor: .gnoTomato)
    }

    func setAddress(_ address: String, label: String? = nil) {
        setAddress(.init(exactly: address), label: label)
    }

    func setAddress(_ address: Address, label: String? = nil) {
        addressInfoView.setAddress(address, label: label)
    }

}
