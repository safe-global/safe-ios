//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class AssetsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // TBD
        view.backgroundColor = UIColor.systemGray6

        // set safe bar item as left bar button item
        let safeItem = SafeBarItem()
        let barItem = UIBarButtonItem(customView: safeItem)
        navigationItem.leftBarButtonItem = barItem
        navigationItem.largeTitleDisplayMode = .always

        // two child view controllers:
        // create and store coin balances view controller
        // create and store collectibles view controller

        // create segment container view
        //      on value changed transition to the child VC (remove current child, add new child, transition views)
        //      container view allows to set the content view controller

        // show selected safe: <-- reusable piece
        // if no safe selected
        //      safeItem must show the "no safe"
        //      the content must show "no safe view"
        // otherwise
        //      content must show "segment container"
    }

}
