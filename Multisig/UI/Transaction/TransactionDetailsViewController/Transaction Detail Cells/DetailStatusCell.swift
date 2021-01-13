//
//  DetailStatusCell.swift
//  Multisig
//
//  Created by Moaaz on 12/3/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailStatusCell: UITableViewCell {
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var appendixLabel: UILabel!
    @IBOutlet private weak var statusIconImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var bottomStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.body)
        appendixLabel.setStyle(.body)
        statusLabel.setStyle(.body)
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setIcon(_ icon: UIImage?) {
        iconImageView.image = icon
    }

    func setStatus(_ status: SCGModels.TxStatus) {
        statusLabel.text = status.title
        appendixLabel.text = status.title
        appendixLabel.isHidden = status.isWaiting
        bottomStackView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
        appendixLabel.textColor = statusColor(status: status)
    }

    func statusColor(status: SCGModels.TxStatus) -> UIColor {
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

extension SCGModels.TxStatus {
    static let queueStatuses = [awaitingConfirmations, .awaitingExecution, .awaitingYourConfirmation]
    static let historyStatuses = [success, .failed, .cancelled]
    static let failedStatuses = [failed, .cancelled]

    var isInQueue: Bool {
        Self.queueStatuses.contains(self)
    }

    var isInHistory: Bool {
        Self.historyStatuses.contains(self)
    }

    var isWaiting: Bool {
        Self.queueStatuses.contains(self)
    }

    var isFailed: Bool {
        Self.failedStatuses.contains(self)
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
