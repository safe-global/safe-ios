//
//  WarningTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 5/19/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WarningTableViewCell: UITableViewCell {
    @IBOutlet private weak var warningView: WarningView!

    func set(image: UIImage? = nil,
             title: String? = nil,
             description: String? = nil,
             backgroundColor: UIColor = .warningBackground) {
        warningView.set(image: image, title: title, description: description, backgroundColor: backgroundColor)
    }
}
