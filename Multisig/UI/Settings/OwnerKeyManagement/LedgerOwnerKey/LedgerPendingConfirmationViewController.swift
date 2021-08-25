//
//  LedgerPedingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerPendingConfirmationViewController: UIViewController {
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    var headerText = "Confirm Transaction"
    var onClose: (() -> Void)?

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(headerText: String? = nil) {
        self.init(nibName: nil, bundle: nil)
        if let headerText = headerText {
            self.headerText = headerText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        topView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))

        // round top corners
        bottomView.layer.cornerRadius = 10
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        headerLabel.text = headerText
        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(.callout)
        cancelButton.setText("Cancel", .filledError)

        modalTransitionStyle = .crossDissolve
    }

    @objc private func close() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }
}

