//
//  LoadingValueCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadingValueCell: UITableViewCell {
    @IBOutlet private weak var titleLable: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    static let rowHeight: CGFloat = 60

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLable.setStyle(.headline)
    }

    func setTitle(_ value: String) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        titleLable.text = value
    }

    func displayLoading() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        titleLable.text = nil
    }
}
