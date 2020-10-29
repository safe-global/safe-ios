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

            let color = isSelected ? #colorLiteral(red: 0, green: 0.5490000248, blue: 0.451000005, alpha: 1) : #colorLiteral(red: 0.6980392157, green: 0.7098039216, blue: 0.6980392157, alpha: 1)
            button.setTitleColor(color, for: .normal)
            button.tintColor = color
        }
    }
}
