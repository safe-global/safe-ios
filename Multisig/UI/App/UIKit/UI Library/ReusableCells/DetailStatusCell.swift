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
        // Initialization code
        titleLabel.setStyle(.body)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func set(title: String) {
        titleLabel.text = title
    }

    func set(icon: String) {
        iconImageView.image = UIImage(named: icon)
    }

    func set(status: TransactionStatus) {
        TransactionStatusView
        statusLabel.text = status.title
        containerStackView.axis = status.isWaiting ? .vertical : .horizontal
        statusIconImageView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
        statusLabel.setStyle(.body)
    }

    func set(style: Style) {
        if style == .body {
            statusLabel.setStyle(.body)
        } else {
            statusLabel.setStyle(.footnote2)
        }
    }

    func statusColor(status: TransactionStatus) -> UIColor {
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

    enum Style {
        case body
        case footnote
    }
}
