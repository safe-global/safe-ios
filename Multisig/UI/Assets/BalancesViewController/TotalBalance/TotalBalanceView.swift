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
    
    override func commonInit() {
        super.commonInit()
    
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sendButton.setText("Send", .filled)
        receiveButton.setText("Receive", .filled)
        amountLabel.setStyle(.normal)
        totalLabel.setStyle(.footnote2)
    }
    
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        onSendClicked?()
    }
    
    @IBAction func receiveButtonClicked(_ sender: Any) {
        onReceivedClicked?()
    }
}
