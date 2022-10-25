//
//  BannerTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class BannerTableViewCell: UITableViewCell {
    var onClose: () -> Void = {}
    var onImport: () -> Void = {}

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var importButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.setStyle(.headline)
        bodyLabel.setStyle(.callout)
        setButton("")
        for label in [headerLabel, bodyLabel] {
            label?.text = nil
        }
        separatorInset.left = .greatestFiniteMagnitude
    }

    func setHeader(_ text: String?) {
        headerLabel.text = text
    }

    func setBody(_ text: String?) {
        bodyLabel.text = text
    }

    func setButton(_ text: String) {
        if text.isEmpty {
            importButton.setTitle(text, for: .normal)
        } else {
            importButton.setText(text, .plain)
        }
    }

    @IBAction func didTapClose(_ sender: Any) {
        onClose()
    }

    @IBAction func didTapImport(_ sender: Any) {
        onImport()
    }
}
