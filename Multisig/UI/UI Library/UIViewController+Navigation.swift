//
//  UIViewController+Navigation.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 11.09.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Pops navigation controller to the root
    func popNavigationStack() {
        if let controllers = navigationController?.viewControllers, controllers.count > 1 {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func navigationTopIs<T>(_ value: T.Type) -> Bool where T: UIViewController {
        navigationTop(as: value) != nil
    }
    
    func navigationTop<T>(as value: T.Type) -> T? where T: UIViewController {
        if let vc = navigationController?.topViewController as? T {
            return vc
        }
        return nil
    }
}
