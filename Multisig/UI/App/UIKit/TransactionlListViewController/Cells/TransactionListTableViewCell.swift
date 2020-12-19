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
    @IBOutlet weak var conflictTypeButtonBarView: UIView!
    @IBOutlet weak var conflictTypeView: UIView!
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nonceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet private weak var appendixLabel: UILabel!
    @IBOutlet private weak var statusIconImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var bottomStackView: UIStackView!
    @IBOutlet weak var confirmationsCountLabel: UILabel!
    @IBOutlet weak var confirmationsCountImageView: UIImageView!
    
    func setTransaction(_ tx: TransactionViewModel, from parent: UIViewController, conflict type: SCG.ConflictType) {
        setContent(TransactionCellView(transaction: tx), from: parent)
    }

    func set(_ title: String = "", image: UIImage = #imageLiteral(resourceName: "ico-settings-tx"), conflictType: SCG.ConflictType = .none, status: SCG.TxStatus = .cancelled, nonce: String = "", date: String = "", info: String = "", confirmationsSubmitted: UInt64 = 0, confirmationsRequired: UInt64 = 0) {
        titleLabel.text = title
        typeImageView.image = image
        nonceLabel.text = "\(nonce)"
        dateLabel.text = date
        infoLabel.text = info
        statusLabel.text = status.title
        appendixLabel.text = status.title
        appendixLabel.isHidden = status.isWaiting
        bottomStackView.isHidden = !status.isWaiting
        statusLabel.textColor = statusColor(status: status)
        appendixLabel.textColor = statusColor(status: status)

        let color = confirmationColor(confirmationsSubmitted, confirmationsRequired)
        confirmationsCountLabel.text = "\(confirmationsSubmitted) out of \(confirmationsRequired)"
        confirmationsCountLabel.textColor = color
        confirmationsCountImageView.tintColor = color

        conflictTypeView.isHidden = conflictType == .none
        conflictTypeButtonBarView.isHidden = conflictType == .end
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

    func confirmationColor(_ confirmationsSubmitted: UInt64 = 0, _ confirmationsRequired: UInt64 = 0) -> UIColor {
        let reminingConfirmations = confirmationsSubmitted > confirmationsRequired ? 0 : confirmationsRequired - confirmationsSubmitted
        return reminingConfirmations > 0 ? .gnoMediumGrey : .gnoHold
    }
}
