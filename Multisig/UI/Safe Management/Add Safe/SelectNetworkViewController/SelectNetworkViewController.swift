//
//  SelectNetworkViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/24/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectNetworkViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService

    private var loadFirstPageDataTask: URLSessionTask?
    private var loadNextPageDataTask: URLSessionTask?

    private var model = NetworksListViewModel()
    
    var completion: () -> Void = { }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(SelectNetworkTableViewCell.self)
        tableView.registerHeaderFooterView(IdleFooterView.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.registerHeaderFooterView(RetryFooterView.self)

        tableView.backgroundColor = .primaryBackground
        tableView.sectionHeaderHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.delegate = self
        tableView.dataSource = self

        navigationItem.title = "Load Gnosis Safe"
        emptyView.setText("Networks will appear here")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.networkSelect)
    }

    override func reloadData() {
        super.reloadData()
        loadFirstPageDataTask?.cancel()
        loadNextPageDataTask?.cancel()
        pageLoadingState = .idle

        loadFirstPageDataTask = clientGatewayService.asyncNetworks { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    // ignore cancellation error due to cancelling the
                    // currently running task. Otherwise user will see
                    // meaningless message.
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        return
                    }
                    self.onError(GSError.error(description: "Failed to load networks", error: error))
                }
            case .success(let page):
                var model = NetworksListViewModel(page.results)
                model.next = page.next

                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.model = model
                    self.onSuccess()
                }
            }
        }
    }

    enum LoadingState {
        case idle, loading, retry
    }

    var pageLoadingState = LoadingState.idle {
        didSet {
            switch pageLoadingState {
            case .idle:
                tableView.tableFooterView = tableView.dequeueHeaderFooterView(IdleFooterView.self)
            case .loading:
                tableView.tableFooterView = tableView.dequeueHeaderFooterView(LoadingFooterView.self)
            case .retry:
                let view = tableView.dequeueHeaderFooterView(RetryFooterView.self)
                view.onRetry = { [unowned self] in
                    self.loadNextPage()
                }
                tableView.tableFooterView = view
                tableView.scrollRectToVisible(view.frame, animated: true)
            }
        }
    }

    private func loadNextPage() {
        // re-entrancy: if loading already, do not cancel and restart
        guard let nextPageUri = model.next, loadNextPageDataTask == nil else { return }

        pageLoadingState = .loading
        do {
            loadNextPageDataTask = try clientGatewayService.asyncNetworks(pageUri: nextPageUri) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            self.pageLoadingState = .idle
                            return
                        }
                        self.onError(GSError.error(description: "Failed to load chains", error: error))
                        self.pageLoadingState = .retry
                    }
                case .success(let page):
                    var model = NetworksListViewModel(page.results)
                    model.next = page.next

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.model.append(from: model)
                        self.onSuccess()
                        self.pageLoadingState = .idle
                    }
                }
                self.loadNextPageDataTask = nil
            }
        } catch {
            onError(GSError.error(description: "Failed to load more chains", error: error))
            pageLoadingState = .retry
        }
    }

    override func onError(_ error: DetailedLocalizedError) {
        App.shared.snackbar.show(error: error)
        if isRefreshing() {
            endRefreshing()
        } else if pageLoadingState == .loading {
            // do nothing here because we want to preserve the visible
            // data when page loading fails
        } else {
            showOnly(view: dataErrorView)
        }
    }
    
    private func isLast(path: IndexPath) -> Bool {
        path.row == model.models.count - 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableHeaderView = TableHeaderView()
        tableHeaderView.set("Select network on which your Safe was created:")
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(SelectNetworkTableViewCell.self, for: indexPath)
        let network = model.models[indexPath.row]

        cell.nameLabel.text = network.chainName
        cell.colorImageView.tintColor = UIColor(hex: network.theme.backgroundColor.description)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = EnterSafeAddressViewController()
        vc.completion = completion
        vc.network = model.models[indexPath.row]
        show(vc, sender: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLast(path: indexPath) {
            loadNextPage()
        }
    }
}
