//
//  RemoveSafeCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class RemoveCell: UITableViewCell {
    var onRemove: (() -> Void)?

    @IBOutlet weak var removeButton: UIButton!
    static let rowHeight: CGFloat = 56
    
    @IBAction func remove() {
        onRemove?()
    }

    func set(title: String) {
        removeButton.setTitle(title, for: .normal)
    }
}
