//
//  ViewControllerFactory.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

enum ViewControllerFactory {

    // Design decision: always have one root view controller because
    // of UIKit memory leaking issues when switching root view controller
    // of the UIWindow.
    static func rootViewController() -> UIViewController {
        let tabBarVC = UITabBarController()
        let balancesTabVC = balancesTabViewController()
        let transactionsTabVC = transactionsTabViewController()
        let settingsTabVC = settingsTabViewController()
        tabBarVC.viewControllers = [balancesTabVC, transactionsTabVC, settingsTabVC]
        tabBarVC.tabBar.barTintColor = .gnoSnowwhite

        if !AppSettings.hasAcceptedTerms() {
            let start = LaunchView(acceptedTerms: .constant(false), onStart: { [weak tabBarVC] in
                tabBarVC?.dismiss(animated: true, completion: nil)
            })
            .environment(\.managedObjectContext, App.shared.coreDataStack.viewContext)
            let vc = UIHostingController(rootView: start)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            DispatchQueue.main.async {
                tabBarVC.present(vc, animated: false, completion: nil)
            }
        }
        return tabBarVC
    }

    private static func balancesTabViewController() -> UIViewController {
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
        noSafesVC.hasSafeViewController = segmentVC
        noSafesVC.noSafeViewController = LoadSafeViewController()

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "Assets", image: #imageLiteral(resourceName: "tab-icon-balances.pdf"), tag: 0)
    }

    private static func transactionsTabViewController() -> UIViewController {
        let transactionsVC = TransactionListViewController()

        let noSafesVC = NoSafesViewController()
        noSafesVC.hasSafeViewController = transactionsVC
        noSafesVC.noSafeViewController = LoadSafeViewController()

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "Transactions", image: #imageLiteral(resourceName: "tab-icon-transactions"), tag: 1)
    }

    private static func settingsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        noSafesVC.hasSafeViewController = SafeSettingsViewController()
        noSafesVC.noSafeViewController = LoadSafeViewController()

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

    static func tabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    static func importOwnerViewController(presenter: UIViewController & CloseModal) -> UIViewController {
        let context = App.shared.coreDataStack.viewContext
        let view = EnterSeedPhraseView().hostSnackbar()
            .environment(\.managedObjectContext, context)
        let vc = UIHostingController(rootView: view)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: presenter, action: #selector(CloseModal.closeModal))
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    static func editSafeNameController(address: String?, name: String?, presenter: UIViewController & CloseModal) -> UIViewController {
        let context = App.shared.coreDataStack.persistentContainer.viewContext
        let view = EditSafeNameView(address: address ?? "", name: name ?? "", onSubmit: { [weak presenter] in
            presenter?.performSelector(onMainThread: #selector(CloseModal.closeModal), with: nil, waitUntilDone: false)
        })

        let vc = UIHostingController(rootView: view
                                        .environment(\.managedObjectContext, context))
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: presenter, action: #selector(CloseModal.closeModal))

        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    static func loadSafeController(presenter: UIViewController & CloseModal) -> UIViewController {
        let context = App.shared.coreDataStack.persistentContainer.viewContext
        let view = EnterSafeAddressView(onSubmit: { [weak presenter] in
            presenter?.performSelector(onMainThread: #selector(CloseModal.closeModal), with: nil, waitUntilDone: true)
        })
        let vc = UIHostingController(rootView: view.environment(\.managedObjectContext, context))
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: presenter, action: #selector(CloseModal.closeModal))
        let nav = UINavigationController(rootViewController: vc)

        return nav
    }
}

@objc protocol CloseModal {
    func closeModal()
}

extension UIViewController: CloseModal {
    func closeModal() {
        dismiss(animated: true, completion: nil)
    }
}
