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
    
    private var safe: Safe? = nil
    
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
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(selectedSafeUpdatedReceived), name: .selectedSafeUpdated, object: nil)
        
        totalBalanceView.onReceivedClicked = { [weak self] in
            let vc = SafeInfoViewController()
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self?.present(vc, animated: true, completion: nil)
        }
        
        totalBalanceView.onSendClicked = { [weak self] in
            //check if safe has an owner imported
            guard let safe = self?.safe else { return }
            if safe.isReadOnly {
                let vc = AddOwnerFirstViewController()
                vc.onSuccess = { [weak self, unowned safe] in
                    if !safe.isReadOnly {
                        self?.showSelectAssetsViewContoller()
                    }
                }
                let navigationController = UINavigationController(rootViewController: vc)
                self?.present(navigationController, animated: true)
            } else {
                self?.showSelectAssetsViewContoller()
            }
        }
    }
    
    private func showSelectAssetsViewContoller() {
        guard let balances = self.balances else { return }
        let vc = SelectAssetViewController(balances: balances)
        self.show(vc, sender: self)
    }
    
    @objc private func updateBalances(_ notification: Notification) {
        let userInfo = notification.userInfo
        totalBalanceView.amount = userInfo?["total"] as? String
        self.balances = userInfo?["balances"] as? [TokenBalance]
        totalBalanceView.sendEnabled = !(balances?.isEmpty ?? true)
    }
    
    @objc private func selectedSafeUpdatedReceived(notification: Notification) {
        //workaround for getting recent safeInfo with safe
        //otherwise first call to Safe.getSelected() won't contain safeInfo data
        //this would lead to safe.isReadOnly not returning correct value
        //TODO: revise workaround
        self.safe = notification.object as? Safe
    }
}
