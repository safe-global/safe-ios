//
//  SigningKeyTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
//import Kingfisher

class SigningKeyTableViewCell: UITableViewCell {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var wcConnectionStatusImageView: UIImageView!
    @IBOutlet weak var keyImageView: UIImageView!

    static let height: CGFloat = 68

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.setDetailImage(nil)
        addressInfoView.copyEnabled = false
        wcConnectionStatusImageView.tintColor = .button
    }

    enum WCConnectionStatus {
        case none
        case connected
        case disconnected
    }

    func set(address: Address, title: String) {
        addressInfoView.setAddress(address, label: title)
    }

    func set(keyImageUrl: URL?, placeholder: UIImage) {
        keyImageView.kf.setImage(with: keyImageUrl, placeholder: placeholder)
    }

    func set(wcConnectionStatus: WCConnectionStatus) {
        switch wcConnectionStatus {
        case .none:
            wcConnectionStatusImageView.isHidden = true

        case .connected:
            wcConnectionStatusImageView.isHidden = false
            wcConnectionStatusImageView.image = UIImage(systemName: "circlebadge.fill")

        case .disconnected:
            wcConnectionStatusImageView.isHidden = false
            wcConnectionStatusImageView.image = UIImage(systemName: "circlebadge")
        }
    }
}
