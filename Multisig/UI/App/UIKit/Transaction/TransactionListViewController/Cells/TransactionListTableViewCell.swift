//
//  TransactionListTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionListTableViewCell: SwiftUITableViewCell {
    @IBOutlet private weak var conflictTypeButtonBarView: UIView!
    @IBOutlet private weak var conflictTypeView: UIView!
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var appendixLabel: UILabel!
    @IBOutlet private weak var statusIconImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var bottomStackView: UIStackView!
    @IBOutlet private weak var confirmationsCountLabel: UILabel!
    @IBOutlet private weak var confirmationsCountImageView: UIImageView!
    
    func setTransaction(_ tx: TransactionViewModel, from parent: UIViewController, conflict type: SCG.ConflictType) {
        setContent(TransactionCellView(transaction: tx), from: parent)
    }

    func set (title: String) {
        titleLabel.text = title
    }

    func set(image: UIImage) {
        typeImageView.image = image
    }

    func set(conflictType: SCG.ConflictType) {
        conflictTypeView.isHidden = conflictType == .none
        conflictTypeButtonBarView.isHidden = conflictType == .end
        nonceLabel.isHidden = conflictType != .none
    }

    func set(nonce: String) {
        nonceLabel.text = "\(nonce)"
    }

    func set(date: String) {
        dateLabel.text = date
    }

    func set(info: String, color: UIColor = .gnoDarkBlue) {
        infoLabel.text = info
        infoLabel.textColor = color
    }

    func set(confirmationsSubmitted: UInt64, confirmationsRequired: UInt64) {
        let color = confirmationColor(confirmationsSubmitted, confirmationsRequired)
        confirmationsCountLabel.text = "\(confirmationsSubmitted) out of \(confirmationsRequired)"
        confirmationsCountLabel.textColor = color
        confirmationsCountImageView.tintColor = color
    }

    func set(status: SCG.TxStatus) {
        statusLabel.text = status.title
        appendixLabel.text = status.title
        appendixLabel.isHidden = status.isWaiting
        bottomStackView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
        appendixLabel.textColor = statusLabel.textColor
        self.contentView.alpha = containerViewAlpha(status: status)
    }

    private func statusColor(status: SCG.TxStatus) -> UIColor {
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

    private func containerViewAlpha(status: SCG.TxStatus) -> CGFloat {
        status.isFailed ? 0.5 : 1
    }

    private func confirmationColor(_ confirmationsSubmitted: UInt64 = 0, _ confirmationsRequired: UInt64 = 0) -> UIColor {
        let reminingConfirmations = confirmationsSubmitted > confirmationsRequired ? 0 : confirmationsRequired - confirmationsSubmitted
        return reminingConfirmations > 0 ? .gnoMediumGrey : .gnoHold
    }
}
