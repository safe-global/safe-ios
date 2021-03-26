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
        let tabBarVC = MainTabBarViewController()

        if !AppSettings.termsAccepted {
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

    static func importOwnerViewController(presenter: UIViewController & CloseModal) -> UIViewController {
        let view = OnboardingImportOwnerKeyViewController()
        let nav = UINavigationController(rootViewController: view)
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
