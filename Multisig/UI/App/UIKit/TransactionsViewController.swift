//
//  TransactionsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionsViewController: UIViewController {
    var headerContainerView: HeaderContainerView!
    lazy var noSafesView = NoSafesView()
    lazy var transactionListViewController = TransactionListViewController()
    var hasSafe = true

    override func viewDidLoad() {
        super.viewDidLoad()
        headerContainerView.loadContent = { [weak self] in
            guard let `self` = self else { return nil }
            if self.hasSafe {
                // embed the transaction vc
                return self.transactionListViewController.view
            } else {
                return self.noSafesView
            }
        }
    }

}

class TransactionListViewController: UIViewController {}
