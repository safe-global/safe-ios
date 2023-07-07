//
//  RelayerExecutionMethodCell.swift
//  Multisig
//
//  Created by Vitaly on 16.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class PaymentMethodCell: UITableViewCell {

    @IBOutlet private weak var paymentMethodIcon: UIImageView!
    @IBOutlet private weak var paymentMethodLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var remainingRelaysLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        paymentMethodLabel.setStyle(.headline)
        descriptionLabel.setStyle(.subheadlineSecondary)
        remainingRelaysLabel.setStyle(.subheadlineSecondary.color(.primary))

        paymentMethodIcon.image = UIImage(named: "ico-payment-relayer")
        let gnosisSymbol = NSTextAttachment()
        gnosisSymbol.image = UIImage(named: "ico-gnosis-chain")
        gnosisSymbol.bounds = CGRectMake(0.0, -2.0, gnosisSymbol.image!.size.width, gnosisSymbol.image!.size.height)
        let gnosisSymbolString = NSMutableAttributedString(attachment: gnosisSymbol)
        gnosisSymbolString.append(
            NSAttributedString(
                string: "\u{00a0}Gnosis Chain\u{00a0}",
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.labelPrimary,
                    NSAttributedString.Key.font: UIFont.gnoFont(forTextStyle: GNOTextStyle.headlinePrimary)
                ]
            )
        )
        let paymentMethodLabelString = NSMutableAttributedString(string: "Sponsored by ", attributes: GNOTextStyle.headline.attributes)
        paymentMethodLabelString.append(gnosisSymbolString)

        paymentMethodLabel.attributedText = paymentMethodLabelString

        descriptionLabel.text = "Transactions per hour:"
        descriptionLabel.numberOfLines = 1

        backgroundView = UIView()
    }

    func setRelaying(_ remaining: Int, _ total: Int) {
        if remaining == ReviewExecutionViewController.MIN_RELAY_TXS_LEFT {
            remainingRelaysLabel.textColor = .error

            let infoSymbol = NSTextAttachment()
            infoSymbol.image = UIImage(named: "ico-info")?.withTintColor(.error)
            infoSymbol.bounds = CGRectMake(0.0, -2.0, infoSymbol.image!.size.width, infoSymbol.image!.size.height)
            let remainingRelaysString = NSMutableAttributedString(attachment: infoSymbol)

            remainingRelaysString.append(
                NSAttributedString(
                    string: "\u{00a0}\(remaining) of \(total)",
                    attributes: [
                        NSAttributedString.Key.foregroundColor: UIColor.error,
                        NSAttributedString.Key.font: UIFont.gnoFont(forTextStyle: GNOTextStyle.headlinePrimary)
                    ]
                )
            )
            remainingRelaysLabel.attributedText = remainingRelaysString

        } else {
            remainingRelaysLabel.textColor = .labelPrimary
            remainingRelaysLabel.text = "\(remaining) of \(total)"
        }
        remainingRelaysLabel.isHidden = false
    }

    func setSignerAccount() {
        paymentMethodIcon.image = UIImage(named: "ico-payment-key")
        paymentMethodLabel.text = "With an owner account"
        descriptionLabel.text = "Select one of the added keys to interact with the transaction"
        descriptionLabel.numberOfLines = 0
        remainingRelaysLabel.isHidden = true
    }

    func setBackgroundColor(_ color: UIColor?) {
        backgroundView?.backgroundColor = color
    }
}
