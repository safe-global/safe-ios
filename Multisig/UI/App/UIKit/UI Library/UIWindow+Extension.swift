//
//  UIWindow+Extension.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIWindow {

    // https://stackoverflow.com/questions/6131205/how-to-find-topmost-view-controller-on-ios
    static func topMostController() -> UIViewController? {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }), let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
    }

}
