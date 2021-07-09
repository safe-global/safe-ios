//
//  RibbonViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class RibbonViewController: ContainerViewController {

    var network: SCGModels.Network?

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var ribbonView: RibbonView!

    private var rootViewController: UIViewController?

    convenience init(rootViewController: UIViewController) {
        self.init(namedClass: nil)
        self.rootViewController = rootViewController
        viewControllers = [rootViewController]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        displayChild(at: 0, in: contentView)

        if let network = network {
            ribbonView.update(scgNetwork: network)
        } else {
            ribbonView.observeSelectedSafe()
        }
    }

    override var navigationItem: UINavigationItem {
        viewControllers.first?.navigationItem ?? super.navigationItem
    }
}
