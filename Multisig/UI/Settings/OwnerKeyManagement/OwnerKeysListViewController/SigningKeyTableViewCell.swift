//
//  SigningKeyTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SigningKeyTableViewCell: UITableViewCell {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var connectionStatusImageView: UIImageView!

    static let height: CGFloat = 68

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.copyEnabled = false
    }

    func configure(keyInfo: KeyInfo, chainID: String?) {
        set(address: keyInfo.address, name: keyInfo.displayName, badgeName: keyInfo.keyType.imageName)
        set(connectionStatus: KeyConnectionStatus.init(keyInfo: keyInfo, chainID: chainID))
    }

    func set(address: Address,
             name: String,
             badgeName: String,
             connectionStatus: KeyConnectionStatus = .none) {
        addressInfoView.setAddress(address, label: name, badgeName: badgeName)
        set(connectionStatus: connectionStatus)
    }

    private func set(connectionStatus: KeyConnectionStatus) {
        connectionStatusImageView.isHidden = connectionStatus == .none
        switch connectionStatus {
        case .none:
            connectionStatusImageView.image = nil
        case .connected:
            connectionStatusImageView.image = UIImage(systemName: "circlebadge.fill")
        case .disconnected:
            connectionStatusImageView.image = UIImage(systemName: "circlebadge")
        case .connectionProblem:
            connectionStatusImageView.image = UIImage(named: "ico-warning")
        }
    }
}


enum KeyConnectionStatus {
    case none
    case connected
    case disconnected
    case connectionProblem

    init(keyInfo: KeyInfo, chainID: String?) {
        switch keyInfo.keyType {
        case .deviceGenerated, .deviceImported, .ledgerNanoX:
            self = .none
        case .walletConnect:
            if WalletConnectClientController.shared.isConnected(keyInfo: keyInfo) {
                if let metadata = keyInfo.metadata,
                    let keyMetadata = KeyInfo.WalletConnectKeyMetadata.from(data: metadata),
                    let chainID = chainID,
                    String(keyMetadata.walletInfo.chainId) == chainID {
                    self = .connected
                } else {
                    self = .connectionProblem
                }
            } else {
                self = .disconnected
            }
        }
    }
}
