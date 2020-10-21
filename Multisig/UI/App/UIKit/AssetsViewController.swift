//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AssetsViewController: UIViewController {

    // segment container view
    // balances view controller
    // collectibles view controller

    override func viewDidLoad() {
        super.viewDidLoad()
        // TBD
        view.backgroundColor = UIColor.systemGray6

        // bar button item + navigation bar does not make the navigation bar
        // the size we want; Also, with 'large title' navigation bar,
        // the shadow disappears, and the bar becomes transparetn.

        // set safe bar item as left bar button item

        // two child view controllers:
        // create and store coin balances view controller
        // create and store collectibles view controller

        // create segment container view
        //      on value changed transition to the child VC (remove current child, add new child, transition views)
        //      container view allows to set the content view controller

        // show selected safe: <-- reusable piece; needs to change the data when SelectedSafeChanged
        // if no safe selected
        //      safeItem must show the "no safe"
        //      the content must show "no safe view"
        // otherwise
        //      safeItem must show the selected safe address
        //      content must show "segment container"
    }

}

/// Encapsulates view hierarchy and interaction with it for the assets tab
class AssetsUIView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {

    }
}
