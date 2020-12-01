//
//  ViewControllerFactory.swift
//  Multisig
//
//  Created by Mouaz Alzahabi on 25.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//
import UIKit

@IBDesignable
class StyledButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 5
    @IBInspectable var roundRect: Bool = true

    override func draw(_ rect: CGRect) {
        // Drawing code
        if cornerRadius != 0 {
            self.layer.cornerRadius = cornerRadius
            self.layer.masksToBounds = true
            self.clipsToBounds = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
