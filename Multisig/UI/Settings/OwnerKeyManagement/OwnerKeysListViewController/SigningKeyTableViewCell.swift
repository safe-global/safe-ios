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

    @IBOutlet weak var cellDetailLabel: UILabel!
    @IBOutlet weak var cellDetailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        addressInfoView.setCopyAddressEnabled(false)
        cellDetailLabel.setStyle(.primary)
        cellDetailImageView.isHidden = true

        cellDetailLabel.isSkeletonable = true
        cellDetailLabel.skeletonTextLineHeight = .relativeToConstraints
        cellDetailLabel.textAlignment = .right
    }

    func configure(keyInfo: KeyInfo, selectedSafeChainID: String?, detail: String? = nil, accessoryImage: UIImage? = nil, enabled: Bool = true, isLoading: Bool = false) {

        let label = keyInfo.displayName
        var connectionChain: Chain? = nil
        if keyInfo.connectedAsDapp {
            let cdwcConnection = keyInfo.connections!.first(where: { connection in
                "\((connection as! CDWCConnection).accounts ?? "")" == keyInfo.address.checksummed
            }) as! CDWCConnection
            let connectionChainId = cdwcConnection.chainId
            connectionChain = Chain.by("\(connectionChainId)")!
        }

        addressInfoView.setAddress(
                keyInfo.address,
                label: label,
                badgeName: keyInfo.keyType.imageName,
                chain: connectionChain,
                connectionStatus: KeyConnectionStatus(keyInfo: keyInfo, chainID: selectedSafeChainID))

        set(connectionStatus: KeyConnectionStatus(keyInfo: keyInfo, chainID: selectedSafeChainID))

        cellDetailLabel.text = detail

        if isLoading {
            cellDetailLabel.showSkeleton(delay: 0.2)
        } else {
            cellDetailLabel.hideSkeleton()
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
            if keyInfo.connectedAsDapp {
                if let _ = keyInfo.connections!.first(where: { connection in
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
