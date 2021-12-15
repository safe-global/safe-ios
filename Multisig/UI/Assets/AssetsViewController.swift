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
    
    private var balances: [TokenBalance]? = nil
    
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
            selector: #selector(updateBalances),
            name: .balanceUpdated,
            object: nil)
        
        totalBalanceView.onSendClicked = { [weak self] in
            let safe = Selection.current().safe
            assert(safe != nil)
            //check if safe has an owner imported
            if safe!.isReadOnly {
                //no -> open add owner key first screen
            } else {
                //yes -> proceed to select asset screen
                guard let balances = self?.balances else {
                    return
                }
                let vc = SelectAssetViewController(balances: balances)
                self?.show(vc, sender: self)
            }
        }
        
        totalBalanceView.onReceivedClicked = { [weak self] in
            let vc = SafeInfoViewController(nibName: nil, bundle: nil)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self?.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc private func updateBalances(_ notification: Notification) {
        let userInfo = notification.userInfo
        totalBalanceView.amount = userInfo?["total"] as? String
        self.balances = userInfo?["balances"] as? [TokenBalance]
        totalBalanceView.sendEnabled = !(balances?.isEmpty ?? true)
    }
}
