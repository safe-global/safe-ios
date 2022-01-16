//
//  CircleView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CircleView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = min(bounds.width, bounds.height) / 2
        layer.cornerRadius = radius
        layer.borderWidth = radius < 16 ? 1 : 2
    }
}
