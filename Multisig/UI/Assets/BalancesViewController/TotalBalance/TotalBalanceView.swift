//
//  TotalBalanceView.swift
//  Multisig
//
//  Created by Vitaly Katz on 13.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TotalBalanceView: UINibView {

    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var receiveButton: UIButton!
    
    var onSendClicked: (() -> Void)?
    var onReceivedClicked: (() -> Void)?
    var amount: String? {
        didSet {
            amountLabel.text = amount
        }
    }
    
    var loading: Bool = false {
        didSet {
            if (loading) {
                //hide amount, show skeleton loader
            } else {
                //show amount, hide skeleton loader
            }
        }
    }
    
    var sendEnabled: Bool = false {
        didSet {
            sendButton.isEnabled = sendEnabled
        }
    }
    
    override func awakeFromNib() {
        amountLabel.setStyle(.title4)
        totalLabel.setStyle(.footnote2)
        sendButton.setText("Send", .filled)
        //TODO: set this attribute in setStyle(:)
        sendButton.tintColor = UIColor.primaryBackground
        receiveButton.setText("Receive", .bordered)
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        onSendClicked?()
    }
    
    @IBAction func receiveButtonClicked(_ sender: Any) {
        onReceivedClicked?()
    }
}
