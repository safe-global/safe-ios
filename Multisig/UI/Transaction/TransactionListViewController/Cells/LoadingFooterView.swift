//
//  LoadingFooterView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 2/4/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadingFooterView: UITableViewHeaderFooterView {
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()
        activityIndicator.stopAnimating()
        activityIndicator.startAnimating()
    }
}
