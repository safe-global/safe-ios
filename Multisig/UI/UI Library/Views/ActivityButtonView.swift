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

    @IBInspectable
    var title: String = "Button"

    var onClick: (() -> Void)?

    var state: ActivityButtonViewState = .normal {
        didSet {
            switch state {
            case .loading:
                actionButton.isEnabled = false
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                actionButton.setText("", .filled)
            case .normal:
                actionButton.isEnabled = true
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                actionButton.setText(title, .filled)
            case .disabled:
                actionButton.isEnabled = false
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                actionButton.setText("", .filled)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        actionButton.setText(title, .filled)
    }

    @IBAction private func actionButtonTouched(_ sender: Any) {
        onClick?()
    }
}
