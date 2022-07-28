//
//  GuardianTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianTableViewCell: UITableViewCell {
    weak var tableView: UITableView?
    
    @IBOutlet private weak var addressInfoView: AddressInfoView!
    @IBOutlet private weak var selectButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!

    var onSelect: (() -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = 10
        containerView.layer.borderColor = UIColor.border.cgColor
        descriptionLabel.setStyle(.primary)
        selectButton.setText("Select as a delegate", .filled)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        tableView?.beginUpdates()
        self.descriptionLabel.numberOfLines = selected ? 0 : 1
        self.selectButton.isHidden = !selected
        tableView?.endUpdates()
    }

    @IBAction func selectButtonTouched(_ sender: Any) {
        onSelect?()
    }

    func set(guardian: Guardian) {
        addressInfoView.setAddress(guardian.address,
                                   ensName: guardian.ensName,
                                   label: guardian.name,
                                   imageUri: guardian.imageURL,
                                   showIdenticon: true,
                                   badgeName: nil,
                                   browseURL: nil,
                                   prefix: nil)
        addressInfoView.copyEnabled = false
        descriptionLabel.text = guardian.reason
    }
}
