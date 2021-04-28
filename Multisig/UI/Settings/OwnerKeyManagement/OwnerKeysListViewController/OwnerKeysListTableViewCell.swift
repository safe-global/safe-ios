//
//  OwnerKeysListTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

protocol OwnerKeysListTableViewCellDelegate: AnyObject {
    func ownerKeysListTableViewDidEdit(cell: OwnerKeysListTableViewCell)
    func ownerKeysListTableViewCellDidRemove(cell: OwnerKeysListTableViewCell)
}
class OwnerKeysListTableViewCell: UITableViewCell {
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    weak var delegate: OwnerKeysListTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        addressInfoView.setDetailImage(nil)
    }

    func set(address: Address, title: String) {
        addressInfoView.setAddress(address, label: title)
    }
    
    @IBAction func editButtonTouched(_ sender: Any) {
        delegate?.ownerKeysListTableViewDidEdit(cell: self)
    }

    @IBAction func deleteButtonTouched(_ sender: Any) {
        delegate?.ownerKeysListTableViewCellDidRemove(cell: self)
    }
}
