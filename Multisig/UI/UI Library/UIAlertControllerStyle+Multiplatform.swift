//
//  UIAlertControllerStyle+Multiplatform.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 10.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIAlertController.Style {
    // Thanks to adamek and matt for the inspiration https://stackoverflow.com/questions/73007791/is-there-a-way-to-detect-which-platform-is-running-in-an-xcode-ios-macos-multipl
    static var multiplatformActionSheet: UIAlertController.Style {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .actionSheet
        } else {
            return .alert
        }
#else
        return .alert
#endif
    }
}
