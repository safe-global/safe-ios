//
//  ActionDetailTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailTableViewCell: UITableViewCell {

    var onTap: () -> Void = {}
    
    func setIndentation(_ value: CGFloat) {
        layoutMargins = UIEdgeInsets(top: 0, left: value, bottom: 0, right: 0)
    }

}
