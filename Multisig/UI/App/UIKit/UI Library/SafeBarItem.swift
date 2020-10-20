//
//  SafeBarItem.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeBarItem: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContents()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContents()
    }

    func loadContents() {
        let nib = UINib(nibName: "SafeBarItem", bundle: Bundle(for: SafeBarItem.self))
        let content = nib.instantiate(withOwner: nil, options: nil)
        let view = content.first as! UIView
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)
    }

}
