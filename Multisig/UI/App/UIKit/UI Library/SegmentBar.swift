//
//  SegmentBar.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SegmentBar: UIView {

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!

    @IBOutlet weak var selectorView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContents()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContents()
    }

    // extract into general procedure
    func loadContents() {
        let nib = UINib(nibName: "SafeBarItem", bundle: Bundle(for: SafeBarItem.self))
        let content = nib.instantiate(withOwner: self, options: nil)
        let view = content.first as! UIView
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)
    }


    // user taps segment -> value changes
    //      target-action
    //      closure callback
    //      delegate protocol

    // select segment programmatically
}
