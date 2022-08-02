//
//  ClaimSuccessViewController.swift
//  Multisig
//
//  Created by Vitaly on 01.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class ClaimSuccessViewController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var tweetBox: TweetBox!

    var amount: String = "10"

    var onOk: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        titleLabel.setStyle(.claimTitle)

        let amountString = "\(amount) SAFE"
        let text = "You successfully created transaction to claim \(amountString) Tokens! Go ahead, approve and execute it. Remember to share your claim on Twitter ;)"
        textLabel.attributedText = text.highlightRange(
            originalStyle: .secondary,
            highlightStyle: .primary,
            textToHightlight: amountString
        )

        tweetBox.setTweet(
            text: "I just got my Safe token Airdrop. Did you get yours? ;)",
            hashtags: [
                "staysafe",
                "safedao",
                "safeairdrop"
            ]
        )

        okButton.setText("OK, Great", .filled)
    }

    @IBAction func didTapOkButton(_ sender: Any) {
        onOk?()
    }
}
