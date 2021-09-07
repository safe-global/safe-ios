//
//  PairedBrowsersHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PairedBrowsersHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!

    var onScan: (() -> Void)?

    @IBAction func scan(_ sender: Any) {
        onScan?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.title3)
        scanButton.setText("Scan QR Code", .filled)
    }
}
