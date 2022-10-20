//
//  ContractVersionCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 16.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ContractVersionStatusCell: UITableViewCell {
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var statusView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var button: UIButton!

    private var versionNumber: String!
    private var versionStatus: ImplementationVersionState!
    private var address: Address?
    private var chainPrefix: String?

    var onViewDetails: (() -> Void)?

    @IBAction private func viewDetails() {
        onViewDetails?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        detailLabel.setStyle(.bodyTertiary)

        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
    }

    func setAddress(_ info: AddressInfo, status: ImplementationVersionState, version: String, prefix: String? = nil) {
        address = info.address
        versionStatus = status
        versionNumber = version
        chainPrefix = prefix

        identiconView.setCircleImage(url: info.logoUri, address: info.address)
        detailLabel.text = prependingPrefixString() + info.address.ellipsized()

        let semiboldConfiguration = UIImage.SymbolConfiguration(weight: .semibold)

        switch versionStatus {
        case .upToDate:
            headerLabel.text = version
            statusView.image = UIImage(systemName: "checkmark", withConfiguration: semiboldConfiguration)
            statusView.tintColor = .success
            statusLabel.setStyle(.headlineSuccess)
            statusLabel.text = "Up to date"

        case .upgradeAvailable:
            headerLabel.text = version
            statusView.image = UIImage(systemName: "exclamationmark.circle", withConfiguration: semiboldConfiguration)
            statusView.tintColor = .error
            statusLabel.setStyle(.headlineError)
            statusLabel.text = "Upgrade available"

        case .unknown:
            headerLabel.text = info.name ?? "Unknown"
            statusView.image = nil
            statusLabel.text = nil
        case .none:
            break
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    @objc private func copyAddress() {
        guard let address = address else { return }
        Pasteboard.string = copyPrefixString() + address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    // visual reaction for user touches
    @objc private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @objc private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }

    private func copyPrefixString() -> String {
        AppSettings.copyAddressWithChainPrefix ? prefixString() : ""
    }

    private func prependingPrefixString() -> String {
        AppSettings.prependingChainPrefixToAddresses ? prefixString() : ""
    }

    private func prefixString() -> String {
        chainPrefix != nil ? "\(chainPrefix!):" : ""
    }
}
