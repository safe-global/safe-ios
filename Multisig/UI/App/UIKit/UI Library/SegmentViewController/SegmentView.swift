//
//  SegmentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SegmentView: UINibView {
    var index: Int!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var selectorView: UIView!

    var onTap: (Int) -> Void = { _ in }

    @IBAction func didTapButton(_ sender: Any) {
        onTap(index)
    }
    
    var isSelected: Bool = false {
        didSet {
            button.isEnabled = !isSelected
            selectorView.isHidden = !isSelected
        }
    }
}
