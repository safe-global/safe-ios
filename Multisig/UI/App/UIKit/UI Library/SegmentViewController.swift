//
//  SegmentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SegmentViewController: ContainerViewController {
    @IBOutlet weak var segmentView: UIView!
    @IBOutlet weak var segmentStackView: UIStackView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var selectorView: UIView!

    var segmentItems = [SegmentBarItem]()
    var selectedIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        // create segment bar buttons
        // configure selector view
        // select default segment
    }

    // update
    //    show selected view controller
    //    update selected button
    //    update unselected button
    //    update selector view constraints
}

struct SegmentBarItem {
    var image: UIImage
    var title: String
}
