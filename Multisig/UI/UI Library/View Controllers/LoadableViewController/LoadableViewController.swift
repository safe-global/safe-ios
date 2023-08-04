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
    // tableView has to be the first view in order for large title "collapse on scroll" animation to be enabled
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: LoadingView!
    @IBOutlet weak var dataErrorView: ScrollableDataErrorView!
    @IBOutlet weak var emptyView: ScrollableEmptyView!
    @IBOutlet private var allViews: [UIView]!
    private var refreshControls: [UIRefreshControl] = []
    private var needsReload: Bool = false
    var notificationCenter = NotificationCenter.default

    /// If true, the screen will reload the data on changing the Safe
    var reactsToSelectedSafeChanges: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        // set up refresh action to trigger data reloading
        emptyView.refreshControl = createRefreshControl()
        dataErrorView.refreshControl = createRefreshControl()
        tableView.refreshControl = createRefreshControl()
        refreshControls = [emptyView.refreshControl,
                           dataErrorView.refreshControl,
                           tableView.refreshControl].compactMap { $0 }

        setNeedsReload()

        if reactsToSelectedSafeChanges {
            notificationCenter.addObserver(
                self,
                selector: #selector(didChangeSelectedSafe),
                name: .selectedSafeChanged,
                object: nil)
        }

        notificationCenter.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(didBecomeOnlineAfterOffline),
            name: .networkHostReachable,
            object: nil)
    }

    func setNeedsReload(_ value: Bool = true) {
        needsReload = value
    }

    @objc func didChangeSelectedSafe() {
        lazyReloadData()
    }

    @objc func willEnterForeground() {
        lazyReloadData()
    }

    @objc func didBecomeOnlineAfterOffline() {
        lazyReloadData()
    }

    @objc func lazyReloadData() {
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

        // iOS quirk: large title does not appear after pushing
        DispatchQueue.main.async { [unowned self] in
            UIView.animate(withDuration: 0.2) { [unowned self] in
                navigationController?.navigationBar.sizeToFit()
            }
        }
    }

    // Managing refresh controls

    func createRefreshControl() -> UIRefreshControl {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(didStartRefreshing), for: .valueChanged)
        return control
    }

    func isRefreshing() -> Bool {
        refreshControls.map(\.isRefreshing).contains(true)
    }

    func startRefreshing() {
        for c in refreshControls {
            c.beginRefreshing()
        }
    }

    func endRefreshing() {
        for c in refreshControls {
            c.endRefreshing()
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
        tableView.reloadData()
    }

    // subclassable
    func onError(_ error: DetailedLocalizedError) {
        App.shared.snackbar.show(error: error)
        if isRefreshing() {
            endRefreshing()
        } else {
            showOnly(view: dataErrorView)
        }
    }

    // subclassable
    var isEmpty: Bool { false }

}
