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
    @IBOutlet private weak var remainingRelaysButton: UIButton!
    @IBOutlet weak var remainingRelaysContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        paymentMethodLabel.setStyle(.headlinePrimary)

        remainingRelaysButton.titleLabel?.setStyle(.headlinePrimary)
        let origImage = UIImage(named: "ico-info")
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        remainingRelaysButton.setImage(tintedImage, for: .normal)
        remainingRelaysButton.tintColor = .labelPrimary
    }

    func setRelaying(_ remaining: Int, _ total: Int) {
        paymentMethodIcon.image = UIImage(named: "ico-relayer-symbol")
        paymentMethodLabel.text = "Via relayer"
        remainingRelaysContainer.isHidden = false
        remainingRelaysButton.titleLabel?.text = "\(remaining) of \(total)"
    }

    func setSignerAccount() {
        paymentMethodIcon.image = UIImage(named: "ico-app-settings-key")
        paymentMethodLabel.text = "With a signer account"
        remainingRelaysContainer.isHidden = true
    }
}
