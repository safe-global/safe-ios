//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

// BaseVC

// loadHeaderContent
// header content -> selected ? segment container : no safes view

// Settings
//  segmentContainerView

class AssetsViewController: UIViewController {
    var headerContainerView: HeaderContainerView!
    lazy var segmentContainerView = SegmentContainerView()
    lazy var noSafesView = NoSafesView()
    lazy var balancesViewController = BalancesViewController()
    lazy var collectiblesViewController = CollectiblesViewController()

    // TBD
    var hasSafe = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // header content -> selected ? segment container : no safes view
        headerContainerView.loadContent = { [weak self] in
            guard let `self` = self else { return nil }
            return self.hasSafe ? self.segmentContainerView : self.noSafesView
        }
        // left segment content -> replace child vc with balances vc
        // right segment content -> replace child vc with collectibles vc
        // selected: get from persistence
    }

}
