//
//  DesktopPairingHeaderView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DesktopPairingHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var scanButton: UIButton!

    var onScan: (() -> Void)?

    @IBAction func scan(_ sender: Any) {
        onScan?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.body)
        scanButton.setText("Scan Code", .filled)
    }
}
