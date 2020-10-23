//
//  HeaderViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Header bar will adapt to the devices size
class HeaderViewController: ContainerViewController {
    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var safeBarButton: SafeBarButton!
    @IBOutlet weak var switchSafeButton: UIButton!
    @IBOutlet weak var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO update bar button depending on the selected safe data
    }

}
