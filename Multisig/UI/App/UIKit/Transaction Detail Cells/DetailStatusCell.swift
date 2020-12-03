//
//  DetailStatusCell.swift
//  Multisig
//
//  Created by Moaaz on 12/3/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailStatusCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var containerStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.body)
        statusLabel.setStyle(.body)
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setIcon(_ icon: UIImage?) {
        iconImageView.image = icon
    }

    func setStatus(_ status: SCG.TxStatus) {
        statusLabel.text = status.title
        containerStackView.axis = status.isWaiting ? .vertical : .horizontal
        statusIconImageView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
    }

    func statusColor(status: SCG.TxStatus) -> UIColor {
        switch status {
        case .awaitingExecution, .awaitingConfirmations, .awaitingYourConfirmation, .pending:
            return .gnoPending
        case .failed:
            return .gnoTomato
        case .cancelled:
            return .gnoDarkGrey
        case .success:
            return .gnoHold
        }
    }
}

extension SCG.TxStatus {
    static let queueStatuses = [awaitingConfirmations, .awaitingExecution, .awaitingYourConfirmation]
    static let historyStatuses = [success, .failed, .cancelled]

    var isInQueue: Bool {
        Self.queueStatuses.contains(self)
    }

    var isInHistory: Bool {
        Self.historyStatuses.contains(self)
    }

    var isWaiting: Bool {
        Self.queueStatuses.contains(self)
    }

    var title: String {
        switch self {
        case .awaitingExecution:
            return "Awaiting execution"
        case .awaitingConfirmations:
            return "Awaiting confirmations"
        case .awaitingYourConfirmation:
            return "Awaiting your confirmation"
        case .pending:
             return "Pending"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .success:
            return "Success"
        }
    }
}
