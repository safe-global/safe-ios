//
//  ImportKeyBannerTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ImportKeyBannerTableViewCell: UITableViewCell {
    var onClose: () -> Void = {}
    var onImport: () -> Void = {}

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var importButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        bodyLabel.setStyle(.primary)
        importButton.setText("Import owner key now", .plain)
        separatorInset.left = .greatestFiniteMagnitude
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose()
    }

    @IBAction func didTapImport(_ sender: Any) {
        onImport()
    }
}
