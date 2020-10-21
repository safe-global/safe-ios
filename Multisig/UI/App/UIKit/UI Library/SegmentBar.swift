//
//  SegmentBar.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SegmentBar: UINibView {

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var selectorView: UIView!

    // user taps segment -> value changes
    //      target-action
    //      closure callback
    //      delegate protocol

    // select segment programmatically
}
