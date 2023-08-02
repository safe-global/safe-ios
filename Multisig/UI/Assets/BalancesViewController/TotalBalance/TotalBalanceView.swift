//
//  TotalBalanceView.swift
//  Multisig
//
//  Created by Vitaly Katz on 13.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import SkeletonView

class TotalBalanceView: UINibView {
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var receiveButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var tokenBanner: SafeTokenBanner!
    @IBOutlet weak var relayInfoBanner: RelayInfoBanner!

    var onSendClicked: (() -> Void)?
    var onReceivedClicked: (() -> Void)?
    var onBuyClicked: (() -> Void)?

    var amount: String? {
        didSet {
            amountLabel.text = amount
        }
    }
    
    var loading: Bool = false {
        didSet {
            if (loading) {
                amountLabel.showSkeleton()
            } else {
                amountLabel.hideSkeleton()
            }
        }
    }
    
    var sendEnabled: Bool = false {
        didSet {
            sendButton.isEnabled = sendEnabled
        }
    }

    var buyEnabled: Bool = false {
        didSet {
            buyButton.isHidden = !buyEnabled
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        amountLabel.skeletonTextLineHeight = .relativeToConstraints
        amountLabel.setStyle(.title1Medium)
        sendButton.setText("Send", .filled)
        //TODO: rename UIColor.claimableAmountLabel
        sendButton.tintColor = UIColor.claimableAmountLabel
        receiveButton.setText("Receive", .filled)
        receiveButton.tintColor = UIColor.claimableAmountLabel
        buyButton.setText("Buy", .filled)
        buyButton.tintColor = UIColor.claimableAmountLabel
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        onSendClicked?()
    }
    
    @IBAction func receiveButtonClicked(_ sender: Any) {
        onReceivedClicked?()
    }

    @IBAction func buyButtonClicked(_ sender: Any) {
        onBuyClicked?()
    }
}
