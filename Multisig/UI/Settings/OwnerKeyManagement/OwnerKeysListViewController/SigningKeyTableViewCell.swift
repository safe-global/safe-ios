//
//  SigningKeyTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SkeletonView

class SigningKeyTableViewCell: UITableViewCell {
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var connectionStatusImageView: UIImageView!

    @IBOutlet weak var networkIndicator: TagView!
    @IBOutlet weak var cellDetailLabel: UILabel!
    @IBOutlet weak var cellDetailImageView: UIImageView!

    static let height: CGFloat = 68

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.setCopyAddressEnabled(false)
        cellDetailLabel.setStyle(.primary)
        cellDetailImageView.isHidden = true

        cellDetailLabel.isSkeletonable = true
        cellDetailLabel.skeletonTextLineHeight = .relativeToConstraints
        cellDetailLabel.textAlignment = .right
    }

    func configure(keyInfo: KeyInfo, chainID: String?, detail: String? = nil, accessoryImage: UIImage? = nil, enabled: Bool = true, isLoading: Bool = false) {
        addressInfoView.setAddress(
            keyInfo.address,
            label: keyInfo.displayName,
            badgeName: keyInfo.keyType.imageName)

        set(connectionStatus: KeyConnectionStatus(keyInfo: keyInfo, chainID: chainID))

        cellDetailLabel.text = detail

        if isLoading {
            cellDetailLabel.showSkeleton(delay: 0.2)
        } else {
            cellDetailLabel.hideSkeleton()
        }

        if keyInfo.connectedAsDapp,
           let connection = keyInfo.walletConnections?.first,
           let chain = Chain.by(String(connection.chainId)),
           let name = chain.name {
            networkIndicator.isHidden = false
            networkIndicator.set(title: name, style: .footnote2.color(chain.textColor))
            networkIndicator.backgroundColor = chain.backgroundColor
        } else {
            networkIndicator.isHidden = true
        }

        cellDetailImageView.image = accessoryImage
        cellDetailImageView.isHidden = accessoryImage == nil


        contentView.alpha = enabled ? 1 : 0.5
    }

    private func set(connectionStatus: KeyConnectionStatus) {
        connectionStatusImageView.isHidden = connectionStatus == .none
        switch connectionStatus {
        case .none:
            connectionStatusImageView.image = nil
        case .connected:
            connectionStatusImageView.image = UIImage(systemName: "circlebadge.fill")
            connectionStatusImageView.tintColor = .button
        case .disconnected:
            connectionStatusImageView.image = UIImage(systemName: "circlebadge", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            connectionStatusImageView.tintColor = .gray2
        case .connectionProblem:
            connectionStatusImageView.image = UIImage(systemName: "exclamationmark.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            connectionStatusImageView.tintColor = .error
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
            if keyInfo.connectedAsDapp {
                if let _  = keyInfo.connections!.first(where: { connection in
                    "\((connection as! CDWCConnection).chainId)" == chainID
                }) {
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
