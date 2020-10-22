//
//  LoadableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadableViewController: UIViewController {
    @IBOutlet weak var loadingView: LoadingView!
    @IBOutlet weak var dataErrorView: ScrollableDataErrorView!
    @IBOutlet weak var emptyView: ScrollableEmptyView!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet var allViews: [UIView]!

    override func viewDidLoad() {
        super.viewDidLoad()
        showOnly(view: loadingView)
    }

    func showOnly(view: UIView) {
        allViews.filter { $0 !== view }.forEach {
            $0.isHidden = true
        }
        view.isHidden = false
    }
}
