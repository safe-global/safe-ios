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

    private var versionStatus: GnosisSafe.VersionStatus!
    private var address: Address?

    var onViewDetails: (() -> Void)?

    @IBAction private func viewDetails() {
        onViewDetails?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        detailLabel.setStyle(.tertiary)
        addTarget(self, action: #selector(didTouchDown(sender:forEvent:)), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp(sender:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
    }

    func setAddress(_ info: AddressInfo) {
        address = info.address
        identiconView.setCircleImage(url: info.logoUri, address: info.address)

        detailLabel.text = info.address.ellipsized()
        versionStatus = App.shared.gnosisSafe.version(implementation: info.address)

        let semiboldConfiguration = UIImage.SymbolConfiguration(weight: .semibold)

        switch versionStatus! {
        case .upToDate(let version):
            headerLabel.text = version
            statusView.image = UIImage(systemName: "checkmark", withConfiguration: semiboldConfiguration)
            statusView.tintColor = .button
            statusLabel.setStyle(.primaryButton)
            statusLabel.text = "Up to date"

        case .upgradeAvailable(let version):
            headerLabel.text = version
            statusView.image = UIImage(systemName: "exclamationmark.circle", withConfiguration: semiboldConfiguration)
            statusView.tintColor = .error
            statusLabel.setStyle(.primaryError)
            statusLabel.text = "Upgrade available"

        case .unknown:
            headerLabel.text = info.name ?? "Unknown"
            statusView.image = nil
            statusLabel.text = nil
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    @objc private func copyAddress() {
        guard let address = address else { return }
        Pasteboard.string = address.checksummed
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)
    }

    // visual reaction for user touches
    @objc private func didTouchDown(sender: UIButton, forEvent event: UIEvent) {
        alpha = 0.7
    }

    @objc private func didTouchUp(sender: UIButton, forEvent event: UIEvent) {
        alpha = 1.0
    }
}
