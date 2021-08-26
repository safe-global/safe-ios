//
//  SigningKeyTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class SigningKeyTableViewCell: UITableViewCell {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var wcConnectionStatusImageView: UIImageView!

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

    func configure(keyInfo: KeyInfo) {

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            set(wcConnectionStatus: .none)
        case .walletConnect:
            let isConnected = WalletConnectClientController.shared.isConnected(keyInfo: keyInfo)
            set(wcConnectionStatus: isConnected ? .connected : .disconnected)
        case .ledgerNanoX:
            set(wcConnectionStatus: .none)
        }

        set(address: keyInfo.address, title: keyInfo.displayName, badgeName: keyInfo.keyType.imageName)
    }

    func set(address: Address, title: String, badgeName: String?) {
        addressInfoView.setAddress(address, label: title, badgeName: badgeName)
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
