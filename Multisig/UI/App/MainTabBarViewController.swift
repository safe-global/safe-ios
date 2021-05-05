//
//  MainTabBarViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import AppTrackingTransparency

class MainTabBarViewController: UITabBarController {
    private weak var transactionsSegementControl: SegmentViewController?
    private var appearsFirstTime: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        let balancesTabVC = balancesTabViewController()
        let transactionsTabVC = transactionsTabViewController()
        let settingsTabVC = settingsTabViewController()
        viewControllers = [balancesTabVC, transactionsTabVC, settingsTabVC]
        tabBar.barTintColor = .secondaryBackground

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHistoryTransactions),
            name: .incommingTxNotificationReceived,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showQueuedTransactions),
            name: .queuedTxNotificationReceived,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard appearsFirstTime else { return }
        appearsFirstTime = false
        // request for users prior 2.15.0 release to confirm IDFA tracking
        if #available(iOS 14, *) {
            if AppSettings.termsAccepted && ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            } else {
                App.shared.appReview.pullAppReviewTrigger()
            }
        } else {
            App.shared.appReview.pullAppReviewTrigger()
        }
    }
    
    private func balancesTabViewController() -> UIViewController {
        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-coins"), title: "Coins"),
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-collectibles"), title: "Collectibles")
        ]
        segmentVC.viewControllers = [
            BalancesViewController(),
            CollectiblesViewController()
        ]
        segmentVC.selectedIndex = 0

        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .assetsNoSafe
        noSafesVC.hasSafeViewController = segmentVC
        noSafesVC.noSafeViewController = loadSafeViewController

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "Assets", image: #imageLiteral(resourceName: "tab-icon-balances.pdf"), tag: 0)
    }

    private func transactionsTabViewController() -> UIViewController {
        let queuedTransactionsViewController = QueuedTransactionsViewController()
        let historyTransactionsViewController = HistoryTransactionsViewController()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-queued-transactions"), title: "QUEUE"),
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-history-transactions"), title: "HISTORY")
        ]
        segmentVC.viewControllers = [
            queuedTransactionsViewController,
            historyTransactionsViewController
        ]
        segmentVC.selectedIndex = 0

        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .transactionsNoSafe
        noSafesVC.hasSafeViewController = segmentVC
        noSafesVC.noSafeViewController = loadSafeViewController

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        transactionsSegementControl = segmentVC
        
        return tabViewController(root: tabRoot, title: "Transactions", image: #imageLiteral(resourceName: "tab-icon-transactions"), tag: 1)
    }

    private func settingsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .settingsSafeNoSafe
        noSafesVC.hasSafeViewController = SafeSettingsViewController()
        noSafesVC.noSafeViewController = loadSafeViewController

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-safe-settings"), title: "Safe Settings"),
            SegmentBarItem(image: #imageLiteral(resourceName: "ico-app-settings"), title: "App Settings")
        ]
        segmentVC.viewControllers = [
            noSafesVC,
            AppSettingsViewController()
        ]
        segmentVC.selectedIndex = 0

        let tabRoot = HeaderViewController(rootViewController: segmentVC)
        return tabViewController(root: tabRoot, title: "Settings", image: #imageLiteral(resourceName: "tab-icon-settings"), tag: 2)
    }

    private func tabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    @objc func showQueuedTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 0
    }

    @objc func showHistoryTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 1
    }

}
