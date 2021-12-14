//
//  TransactionSuccessScreen.swift
//  Multisig
//
//  Created by Vitaly Katz on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionSuccessScreen: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var viewDetailsButton: UIButton!
    
    var amount: String = ""
    var transactionDetails: SCGModels.TransactionDetails?
    
    convenience init(amount: String, transactionDetails: SCGModels.TransactionDetails? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.amount = amount
        self.transactionDetails = transactionDetails
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true

        titleLabel.setStyle(.headline)
        statusLabel.setStyle(.primary)
        statusLabel.text = "Your request to send \(amount) is submitted and needs to be confirmed by other owners."
        viewDetailsButton.setText("View details", .filled)
    }
    
    @IBAction func viewDetailsClicked(_ sender: Any) {
        NotificationCenter.default.post(name: .initiateTxNotificationReceived,
                                        object: self,
                                        userInfo: transactionDetails == nil ? nil : ["transactionDetails": transactionDetails!])
        //TODO check if resetting of the property is needed
        navigationController?.isNavigationBarHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
}
