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

    static func faceIDUnlockViewController(completion: @escaping () -> Void) -> UIViewController {
        let vc = FaceIDUnlockViewController()
        vc.completion = { _, _ in
            completion()
        }
        return UINavigationController(rootViewController: vc)
    }

    static func enterPasscodeViewController(showsCloseButton: Bool,
                                            completion: @escaping (_ result: EnterPasscodeViewController.Result) -> Void) -> UIViewController {
        let vc = EnterPasscodeViewController()
        vc.showsCloseButton = showsCloseButton
        vc.passcodeCompletion = completion
        return UINavigationController(rootViewController: vc)
    }

    static func addOwnerViewController(completion: @escaping () -> Void) -> UIViewController {
        let controller = AddOwnerKeyViewController(completion: completion)
        let nav = AddKeyNavigationController(rootViewController: controller)
        return nav
    }

    static func selectTopUpAddress(safe: Safe) -> UIViewController {
        let vc = SelectTopUpAddressViewController()

        Self.addCloseButton(vc)
        vc.safe = safe
        vc.onSelect = { [weak vc] address in
            vc?.dismiss(animated: true, completion: {
                App.shared.ramper.startOnRamp(address: address, chain: safe.chain!)
            })
        }

        return UINavigationController(rootViewController: vc)
    }

    static func transactionDetailsViewController(transactionId: String) -> UIViewController {
        let vc = TransactionDetailsViewController(transactionID: transactionId)
        return modalWithRibbon(viewController: vc)
    }

    static func transactionDetailsViewController(safeTxHash: Data) -> UIViewController {
        let vc = TransactionDetailsViewController(safeTxHash: safeTxHash)
        return modalWithRibbon(viewController: vc)
    }
    
    static func transactionDetailsViewController(transaction: SCGModels.TransactionDetails) -> UIViewController {
        let vc = TransactionDetailsViewController(transactionID: transaction.txId)
        return modalWithRibbon(viewController: vc)
    }

    static func modalWithRibbon(viewController: UIViewController, chain: SCGModels.Chain? = nil, storedChain: Chain? = nil) -> UIViewController {
        viewController.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: viewController, action: #selector(CloseModal.closeModal))
        let ribbon = RibbonViewController(rootViewController: viewController)
        ribbon.chain = chain
        ribbon.storedChain = storedChain
        let navController = UINavigationController(rootViewController: ribbon)
        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navController.navigationBar.backgroundColor = .backgroundSecondary
        }
        return navController
    }

    static func ribbonWith(viewController: UIViewController) -> RibbonViewController {
        RibbonViewController(rootViewController: viewController)
    }

    static func addCloseButton(_ vc: UIViewController) {
        vc.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: vc, action: #selector(CloseModal.closeModal))
    }

    static func removeNavigationBarBorder(_ vc: UIViewController) {
        // remove underline from navigationItem
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .backgroundSecondary
        navigationBarAppearance.shadowColor = .clear

        vc.navigationItem.scrollEdgeAppearance = navigationBarAppearance
    }

    static func makeTransparentNavigationBar(_ vc: UIViewController) {
        removeNavigationBarBorder(vc)

        vc.navigationItem.hidesBackButton = true

        // disable swipe back
        vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        vc.navigationController?.isNavigationBarHidden = false
    }

    static func makeMultiLinesNavigationBar(_ vc: UIViewController) {
        vc.navigationItem.setValuesForKeys(["__largeTitleTwoLineMode": true])
    }

    static func modal(viewController: UIViewController,
                      halfScreen: Bool = false,
                      largeTitles: Bool = false) -> UIViewController {
        Self.addCloseButton(viewController)
        let navController = UINavigationController(rootViewController: viewController)
        if largeTitles {
            navController.navigationBar.prefersLargeTitles = true
            navController.navigationItem.largeTitleDisplayMode = .always
        }
        
        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navController.navigationBar.backgroundColor = .backgroundSecondary
        }
        if halfScreen, #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        return navController
    }
    
    static func pageSheet(viewController: UIViewController, halfScreen: Bool = false) -> UIViewController {
        viewController.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: viewController, action: #selector(CloseModal.closeModal))
        let navController = UINavigationController(rootViewController: viewController)
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .clear
        navigationBarAppearance.shadowColor = .clear
        navController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navController.modalPresentationStyle = .pageSheet
        if halfScreen, #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navController.navigationBar.backgroundColor = .backgroundSecondary
        }
        navController.view.backgroundColor = .backgroundSecondary
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
