//
//  RemoveSafeCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class RemoveSafeCell: UITableViewCell {
    var onRemove: (() -> Void)?

    static let rowHeight: CGFloat = 56
    
    @IBAction func removeSafe() {
        onRemove?()
    }
}
