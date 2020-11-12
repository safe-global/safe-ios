//
//  ImportedKeyCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 11.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportedKeyCell: UITableViewCell {
    @IBOutlet private weak var addressWithTitleView: AddressWithTitleView!
    var onRemove: (() -> Void)?

    @IBAction func removeKey() {
        onRemove?()
    }

    func setAddress(_ value: Address) {
        addressWithTitleView.setAddress(value)
    }

    func setName(_ value: String) {
        addressWithTitleView.setName(value)
    }
}
