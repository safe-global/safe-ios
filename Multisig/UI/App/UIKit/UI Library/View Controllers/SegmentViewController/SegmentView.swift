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
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var selectorView: UIView!

    var onTap: (Int) -> Void = { _ in }

    override func commonInit() {
        super.commonInit()
        button.titleLabel?.setStyle(.caption1)
    }

    @IBAction private func didTapButton(_ sender: Any) {
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

    func setImage(_ image: UIImage) {
        button.setImage(image, for: .normal)
    }

    func setTitle(_ value: String) {
        button.setTitle(value, for: .normal)
    }
}
