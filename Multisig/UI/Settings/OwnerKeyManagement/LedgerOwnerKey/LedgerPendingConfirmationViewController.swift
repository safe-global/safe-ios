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
    @IBOutlet private weak var safeTxHashLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    var headerText = "Confirm Transaction"
    var ledgerHash: String!
    var onClose: (() -> Void)?

    @IBAction private func cancel(_ sender: Any) {
        close()
    }

    convenience init(ledgerHash: String, headerText: String? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.ledgerHash = ledgerHash
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
        safeTxHashLabel.attributedText = highlightedLedgerHash
        cancelButton.setText("Cancel", .plain)

        modalTransitionStyle = .crossDissolve
    }

    private func close() {
        dismiss(animated: true)
    }

    var highlightedLedgerHash: NSAttributedString {
        let value = ledgerHash!
        let style = GNOTextStyle.tertiary
        let attributedString = NSMutableAttributedString(
            string: value,
            attributes: [
                .font: UIFont.gnoFont(forTextStyle: style),
                .foregroundColor: style.color!,
                .kern: -0.41
            ]
        )
        // first 4 digits
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: 0, length: 4))
        // last 4 digits
        attributedString.addAttribute(
            .foregroundColor, value: UIColor.primaryLabel, range: NSRange(location: value.count - 4, length: 4))
        return attributedString
    }
}
