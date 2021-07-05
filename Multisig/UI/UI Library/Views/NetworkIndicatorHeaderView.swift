//
//  NetworkIndicatorHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class NetworkIndicatorHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var networkIndicator: NetworkIndicator!

    static let height: CGFloat = 22

    var text: String? {
        get { networkIndicator.text }
        set { networkIndicator.text = newValue }
    }

    var dotColor: UIColor? {
        get { networkIndicator.dotColor }
        set { networkIndicator.dotColor = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = UIView(frame: bounds)        
        networkIndicator.layer.cornerRadius = 3
    }
}
