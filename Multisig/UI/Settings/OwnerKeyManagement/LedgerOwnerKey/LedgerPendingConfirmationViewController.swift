//
//  LedgerPedingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerPendingConfirmationViewController: UIViewController {
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    // NOTE: hidden until further releases
    @IBOutlet private weak var safeTxHashLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    var headerText = "Confirm Transaction"
    var safeTxHash: HashString!
    var onClose: (() -> Void)?

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(safeTxHash: HashString, headerText: String? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.safeTxHash = safeTxHash
        if let headerText = headerText {
            self.headerText = headerText
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // round top corners
        bottomView.layer.cornerRadius = 8
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        headerLabel.text = headerText
        headerLabel.setStyle(.headline)
        descriptionLabel.setStyle(.callout)
        safeTxHashLabel.attributedText = safeTxHash.highlighted
        cancelButton.setText("Cancel", .plain)

        modalTransitionStyle = .crossDissolve
    }

    private func close() {
        dismiss(animated: true)
    }
}

