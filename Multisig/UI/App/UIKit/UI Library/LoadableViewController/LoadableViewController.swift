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
    var scrollViews: [UIScrollView] = []
    private var needsReload: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // set up refresh action to trigger data reloading
        scrollViews = [dataErrorView.scrollView, emptyView.scrollView, tableView]
        scrollViews.forEach { view in
            view.refreshControl = createRefreshControl()
        }
        // set the state needsReload
        setNeedsReload()
    }

    func setNeedsReload(_ value: Bool = true) {
        needsReload = value
    }

    // on appear
    // if needsReload, reload the data; needsReload = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needsReload {
            setNeedsReload(false)
            reloadData()
        }
    }

    // Managing refresh controls

    func createRefreshControl() -> UIRefreshControl {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(didStartRefreshing), for: .valueChanged)
        return control
    }

    func isRefreshing() -> Bool {
        scrollViews.compactMap(\.refreshControl?.isRefreshing).contains(true)
    }

    func endRefreshing() {
        scrollViews.compactMap(\.refreshControl).forEach { control in
            control.endRefreshing()
        }
    }

    @objc func didStartRefreshing() {
        reloadData()
    }

    // Managing presented subviews

    func showOnly(view: UIView) {
        allViews.filter { $0 !== view }.forEach {
            $0.isHidden = true
        }
        view.isHidden = false
    }

    // Managing data loading

    // subclassable
    func reloadData() {
        if !isRefreshing() {
            showOnly(view: loadingView)
        }
    }

    // subclassable
    func onSuccess() {
        endRefreshing()
        if isEmpty {
            showOnly(view: emptyView)
        } else {
            showOnly(view: tableView)
        }
    }

    // subclassable
    func onError() {
        // show snackbar
        if isRefreshing() {
            endRefreshing()
        } else {
            showOnly(view: dataErrorView)
        }
    }

    // subclassable
    var isEmpty: Bool { false }

}
