//
//  UIViewController+NavigationItem.swift
//  Multisig
//
//  Created by Moaaz on 1/22/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
extension UIViewController {
    func createCloseButton () {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ico-close-x"), style: .plain, target: self, action: #selector(CloseModal.closeModal))
        navigationItem.leftBarButtonItem?.tintColor = .systemGray3
    }
}
