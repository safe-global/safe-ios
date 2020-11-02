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

    override func commonInit() {
        super.commonInit()
        button.titleLabel?.setStyle(.caption1)
    }

    @IBAction func didTapButton(_ sender: Any) {
        onTap(index)
    }
    
    var isSelected: Bool = false {
        didSet {
            selectorView.isHidden = !isSelected

            let color: UIColor = isSelected ? .gnoHold : .gnoMediumGrey
            button.setTitleColor(color, for: .normal)
            button.tintColor = color
        }
    }
}
