//
//  MainTabBarViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {
    var onFirstAppear: (_ vc: MainTabBarViewController) -> Void = { _ in }

    private weak var transactionsSegementControl: SegmentViewController?
    private var appearsFirstTime: Bool = true

    lazy var balancesTabVC: UIViewController = {
        balancesTabViewController()
    }()

    lazy var transactionsTabVC: UIViewController = {
        transactionsTabViewController()
    }()

    lazy var dappsTabVC: UIViewController = {
        dappsTabViewController()
    }()

    lazy var settingsTabVC: UIViewController = {
        settingsTabViewController()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTabs()
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showTransactionDetails),
            name: .confirmationTxNotificationReceived,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTabs),
            name: .updatedExperemental,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard appearsFirstTime else { return }
        appearsFirstTime = false

        onFirstAppear(self)
    }
    
    private func balancesTabViewController() -> UIViewController {
        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-coins")!, title: "Coins"),
            SegmentBarItem(image: UIImage(named: "ico-collectibles")!, title: "Collectibles")
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
        return tabViewController(
            root: tabRoot, title: "Assets", image: UIImage(named: "tab-icon-balances.pdf")!, tag: 0)
    }

    private func transactionsTabViewController() -> UIViewController {
        let queuedTransactionsViewController = QueuedTransactionsViewController()
        let historyTransactionsViewController = HistoryTransactionsViewController()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-queued-transactions")!, title: "QUEUE"),
            SegmentBarItem(image: UIImage(named: "ico-history-transactions")!, title: "HISTORY")
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
        
        return tabViewController(
            root: tabRoot, title: "Transactions", image: UIImage(named: "tab-icon-transactions")!, tag: 1)
    }

    private func dappsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .dappsNoSafe
        noSafesVC.hasSafeViewController = DappsViewController()
        noSafesVC.noSafeViewController = loadSafeViewController

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "Dapps", image: UIImage(named: "tab-icon-dapps")!, tag: 2)
    }

    private func settingsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .settingsSafeNoSafe
        noSafesVC.hasSafeViewController = SafeSettingsViewController()
        noSafesVC.noSafeViewController = loadSafeViewController

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-safe-settings")!, title: "Safe Settings"),
            SegmentBarItem(image: UIImage(named: "ico-app-settings")!, title: "App Settings")
        ]
        segmentVC.viewControllers = [
            noSafesVC,
            AppSettingsViewController()
        ]
        segmentVC.selectedIndex = 0

        let tabRoot = HeaderViewController(rootViewController: segmentVC)
        return tabViewController(root: tabRoot, title: "Settings", image: UIImage(named: "tab-icon-settings")!, tag: 2)
    }

    private func tabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    @objc private func showQueuedTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 0
    }

    @objc private func showHistoryTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 1
    }

    @objc private func updateTabs() {
        if App.configuration.toggles.walletConnectEnabled {
            viewControllers = [balancesTabVC, transactionsTabVC, dappsTabVC, settingsTabVC]
        } else {
            viewControllers = [balancesTabVC, transactionsTabVC, settingsTabVC]
        }
    }

    @objc func showTransactionDetails(_ notification: Notification) {
        guard let safeTxHash = App.shared.notificationHandler.transactionDetailsPayload else { return }
        App.shared.notificationHandler.transactionDetailsPayload = nil
        let vc = ViewControllerFactory.transactionDetailsViewController(safeTxHash: safeTxHash)
        present(vc, animated: true, completion: nil)
    }
}
