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

    static func termsViewController(completion: @escaping () -> Void) -> UIViewController {
        let start = LaunchView(acceptedTerms: .constant(false), onStart: completion)
            .environment(\.managedObjectContext, App.shared.coreDataStack.viewContext)

        let startVC = UIHostingController(rootView: start)
        return startVC
    }

    static func tabBarViewController(completion: @escaping (_ tabBar: MainTabBarViewController) -> Void) -> UIViewController {
        let tabBarVC = MainTabBarViewController()
        tabBarVC.onFirstAppear = completion
        return tabBarVC
    }

    static func createPasscodeViewController(completion: @escaping () -> Void) -> UIViewController {
        UINavigationController(rootViewController: CreatePasscodeViewController(completion))
    }

    static func enterPasscodeViewController(completion: @escaping () -> Void) -> UIViewController {
        let vc = EnterPasscodeViewController()
        vc.showsCloseButton = false
        // because close button is hidden, this will complete only
        // if passcode is correct or if the data is deleted.
        // in both cases, we want to trigger completion closure
        vc.passcodeCompletion = { _ in
            completion()
        }
        return UINavigationController(rootViewController: vc)
    }

    static func addOwnerViewController(completion: @escaping () -> Void) -> UIViewController {
        let controller = AddOwnerKeyViewController(completion: completion)
        let nav = UINavigationController(rootViewController: controller)
        return nav
    }

    static func transactionDetailsViewController(safeTxHash: Data) -> UIViewController {
        let vc = TransactionDetailsViewController(safeTxHash: safeTxHash)
        return modalWithRibbon(viewController: vc)
    }

    static func modalWithRibbon(viewController: UIViewController, chain: SCGModels.Chain? = nil, storedChain: Chain? = nil) -> UIViewController {
        viewController.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: viewController, action: #selector(CloseModal.closeModal))
        let ribbon = RibbonViewController(rootViewController: viewController)
        ribbon.chain = chain
        ribbon.storedChain = storedChain
        let navController = UINavigationController(rootViewController: ribbon)
        return navController
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
