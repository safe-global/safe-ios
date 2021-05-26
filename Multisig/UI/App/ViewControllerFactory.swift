//
//  ViewControllerFactory.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import AppTrackingTransparency

enum ViewControllerFactory {

    // Design decision: always have one root view controller because
    // of UIKit memory leaking issues when switching root view controller
    // of the UIWindow.

    static func termsViewController(completion: @escaping () -> Void) -> UIViewController {
        let start = LaunchView(acceptedTerms: .constant(false), onStart: {
            // user agreed to terms

            if #available(iOS 14, *) {
                // will present the tracking authorization pop-up
                ATTrackingManager.requestTrackingAuthorization { status in
                    // user gave the response
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            AppSettings.trackingEnabled = true
                        case .denied, .notDetermined, .restricted:
                            AppSettings.trackingEnabled = false
                        @unknown default:
                            AppSettings.trackingEnabled = false
                        }
                        // tracking authorization pop-up is dismissed.

                        completion()
                    }
                }
                // tracking authorization pop-up presented.
                return
            }
            // on pre-iOS 14, enables tracking
            AppSettings.trackingEnabled = true

            completion()
        })
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
        vc.completion = { _ in
            completion()
        }
        return UINavigationController(rootViewController: vc)
    }

    static func addOwnerViewController(presenter: UIViewController & CloseModal) -> UIViewController {
        let controller = AddOwnerKeyViewController()
        let nav = UINavigationController(rootViewController: controller)
        return nav
    }

    static func transactionDetailsViewController(safeTxHash: Data) -> UIViewController {
        let vc = TransactionDetailsViewController(safeTxHash: safeTxHash)
        vc.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: vc, action: #selector(CloseModal.closeModal))
        let navController = UINavigationController(rootViewController: vc)
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
