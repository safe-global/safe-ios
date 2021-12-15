//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 15.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AssetsViewController: ContainerViewController {

    @IBOutlet private weak var totalBalanceView: TotalBalanceView!
    
    @IBOutlet private weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-coins")!, title: "Coins"),
            SegmentBarItem(image: UIImage(named: "ico-collectibles")!, title: "Collectibles")
        ]
        segmentVC.viewControllers = [
            BalancesViewController(),
            CollectiblesUnsupportedViewController(nibName: nil, bundle: nil)
        ]
        segmentVC.selectedIndex = 0
        
        viewControllers.append(segmentVC)
        
        displayChild(at: 0, in: contentView)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTotalBalance(_:)),
            name: .totalBalanceUpdated,
            object: nil)
    }
    
    @objc private func updateTotalBalance(_ notification: Notification) {
        guard let totalAmount = notification.userInfo?["totalAmount"] as? String else {
            return
        }
        totalBalanceView.amount = totalAmount
    }
}
