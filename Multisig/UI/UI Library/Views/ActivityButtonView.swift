//
//  ActivityButtonView.swift
//  Multisig
//
//  Created by Moaaz on 1/10/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

enum ActivityButtonViewState {
    case loading
    case normal
    case disabled
}

class ActivityButtonView: UINibView {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var rejectButton: UIButton!

    @IBInspectable
    var actionTitle: String = "Button"
    @IBInspectable
    var rejectTitle: String = "Reject"

    var onAction: (() -> Void)?
    var onReject: (() -> Void)?

    var state: ActivityButtonViewState = .normal {
        didSet {
            switch state {
            case .loading:
                actionButton.isEnabled = false
                rejectButton.isEnabled = false
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                actionButton.setText("", .filled)
                rejectButton.setText("", .filledError)
            case .normal:
                actionButton.isEnabled = true
                rejectButton.isEnabled = true
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                actionButton.setText(actionTitle, .filled)
                rejectButton.setText(rejectTitle, .filledError)
            case .disabled:
                actionButton.isEnabled = false
                rejectButton.isEnabled = false
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                actionButton.setText("", .filled)
                rejectButton.setText("", .filledError)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        actionButton.setText(actionTitle, .filled)
        rejectButton.setText(rejectTitle, .filledError)
    }

    @IBAction func rejectButtonTouched(_ sender: Any) {
        onReject?()
    }

    @IBAction private func actionButtonTouched(_ sender: Any) {
        onAction?()
    }

    func set(rejectionEnabled: Bool = false) {
        rejectButton.isHidden = !rejectionEnabled
    }
}
