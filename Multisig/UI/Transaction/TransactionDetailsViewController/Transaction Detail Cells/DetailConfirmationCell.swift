//
//  DetailConfirmationCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailConfirmationCell: UITableViewCell {
    @IBOutlet private weak var stackView: UIStackView!

    func setConfirmations(_ confirmations: [Address],
                          required: Int,
                          status: SCGModels.TxStatus,
                          executor: Address?) {
        let bounds = contentView.bounds
        var views: [UIView] = []

        views.append(ConfirmationCreatedPiece(frame: bounds))

        views += confirmations.map { address -> ConfirmationConfirmedPiece in
            let v = ConfirmationConfirmedPiece(frame: bounds)
            v.setText("Confirmed")
            v.setAddress(address)
            return v
        }

        switch status {
        case .awaitingConfirmations, .awaitingYourConfirmation:
            let status = ConfirmationStatusPiece(frame: bounds)
            let confirmationsRemaining = required - confirmations.count
            if confirmationsRemaining > 0 {
                status.setText("Execute (\(confirmationsRemaining) more confirmations needed)", style: GNOTextStyle.body.color(.gnoMediumGrey))
            } else {
                status.setText("Execute", style: GNOTextStyle.body.color(.gnoMediumGrey))
            }
            status.setSymbol("circle", color: .gnoMediumGrey)
            views.append(status)

        case .awaitingExecution:
            let status = ConfirmationStatusPiece(frame: bounds)
            status.setText("Execute", style: GNOTextStyle.body.color(.gnoHold))
            status.setSymbol("circle", color: .gnoHold)
            views.append(status)

        case .cancelled:
            let status = ConfirmationStatusPiece(frame: bounds)
            status.setText("Cancelled", style: GNOTextStyle.body.color(.black))
            status.setSymbol("xmark.circle", color: .black)
            views.append(status)

        case .failed:
            let status = ConfirmationStatusPiece(frame: bounds)
            status.setText("Failed", style: GNOTextStyle.body.color(.gnoTomato))
            status.setSymbol("xmark.circle", color: .gnoTomato)
            views.append(status)

        case .success:
            if let address = executor {
                let success = ConfirmationConfirmedPiece(frame: bounds)
                success.setText("Executed")
                success.setShowsBar(false)
                success.setAddress(address)
                views.append(success)
            } else {
                let status = ConfirmationStatusPiece(frame: bounds)
                status.setText("Executed", style: GNOTextStyle.body.color(.gnoHold))
                status.setSymbol("checkmark.circle", color: .gnoHold)
                views.append(status)
            }

        case .pending:
            let status = ConfirmationStatusPiece(frame: bounds)
            status.setText("Pending", style: GNOTextStyle.body.color(.gnoHold))
            status.setSymbol("circle", color: .gnoHold)
            views.append(status)

        }

        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

}
