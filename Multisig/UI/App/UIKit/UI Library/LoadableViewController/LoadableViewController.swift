//
//  LoadableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Reusable class that implements common screen configuration for screens
/// that load data, for example, balances or transaction list.
///
/// Subclasses define the loading behavior in the `reloadData()` method
/// and use (or subclass) `onSuccess()`, `onError(), and `isEmpty` to
/// control which view is shown.
///
/// There are the following views that can be shown:
///      - showOnly(view: loadingView) - shown when reloadData starts, unless a refresh control is active
///      - showOnly(view: dataErrorView) - shown onError() unles a refresh control was active.
///      - showOnly(view: emptyView) - shown onSuccess() when isEmpty returns true
///      - showOnly(view: tableView) - shown onSuccess() in isEmpty is false
class LoadableViewController: UIViewController {
    @IBOutlet weak var loadingView: LoadingView!
    @IBOutlet weak var dataErrorView: ScrollableDataErrorView!
    @IBOutlet weak var emptyView: ScrollableEmptyView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var allViews: [UIView]!
    var scrollViews: [UIScrollView] = []
    private var needsReload: Bool = false
    let notificationCenter = NotificationCenter.default

    override func viewDidLoad() {
        super.viewDidLoad()
        // set up refresh action to trigger data reloading
        scrollViews = [dataErrorView.scrollView, emptyView.scrollView, tableView]
        scrollViews.forEach { view in
            view.refreshControl = createRefreshControl()
        }
        setNeedsReload()

        notificationCenter.addObserver(
            self, selector: #selector(didChangeSafe), name: .selectedSafeChanged, object: nil)
    }

    func setNeedsReload(_ value: Bool = true) {
        needsReload = value
    }

    @objc func didChangeSafe() {
        let isOnScreen = viewIfLoaded?.window != nil
        if isOnScreen {
            reloadData()
        } else {
            // Save battery and network requests if the view is off-screen
            setNeedsReload()
        }
    }

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
            tableView.reloadData()
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
