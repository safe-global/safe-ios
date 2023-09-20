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
    var screenTitle: String!
    var descriptionText: String!
    var showWeb2SupportHint: Bool = false
    var trackingEvent: TrackingEvent?
    var preselectedChainId: String?

    var completion: (SCGModels.Chain) -> Void = { _ in }
    
    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(descriptionText?.isEmpty == false, "Developer error: expect to have a description")
        assert(screenTitle?.isEmpty == false, "Developer error: expect to have an screen title")

        tableView.registerCell(SelectNetworkTableViewCell.self)
        tableView.registerHeaderFooterView(IdleFooterView.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.registerHeaderFooterView(RetryFooterView.self)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        tableView.backgroundColor = .backgroundSecondary
        tableView.sectionHeaderHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.title = screenTitle
        emptyView.setTitle("Networks will appear here")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        } else {
            Tracker.trackEvent(.networkSelect)
        }
    }

    override func reloadData() {
        super.reloadData()
        loadFirstPageDataTask?.cancel()
        loadNextPageDataTask?.cancel()
        pageLoadingState = .idle

        loadFirstPageDataTask = clientGatewayService.asyncChains { [weak self] result in
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
                    self.findPreselectedChainId()
                }
            }
        }
    }
    
    // Select the chain automatically based on the given input chain id
    private func findPreselectedChainId() {
        guard let chainId = preselectedChainId else { return }
        
        if let chain = model.models.first(where: { $0.id == chainId }) {
            completion(chain)
        } else if model.next != nil {
            loadNextPage()
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
            loadNextPageDataTask = try clientGatewayService.asyncChains(pageUri: nextPageUri) { [weak self] result in
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
                        self.findPreselectedChainId()
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
        tableHeaderView.set(descriptionText)
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(SelectNetworkTableViewCell.self, for: indexPath)
        let chain = model.models[indexPath.row]
        cell.setText(chain.chainName)
        if showWeb2SupportHint && chain.isSupported(feature: Chain.Feature.web3authCreateSafe.rawValue) {
            var text = NSMutableAttributedString(string: "Enjoy ",
                                                 attributes: GNOTextStyle.subheadlineSecondary.attributes)
            
            if AppConfiguration.FeatureToggles.socialLogin {
                text.append(NSAttributedString(string: "free transactions ", attributes: GNOTextStyle.bodyPrimary.attributes))
                text.append(NSAttributedString(string: "and ", attributes: GNOTextStyle.subheadlineSecondary.attributes))
                text.append(NSAttributedString(string: "social login account creation!", attributes: GNOTextStyle.bodyPrimary.attributes))
            } else {
                text.append(NSAttributedString(string: "free transactions!", attributes: GNOTextStyle.bodyPrimary.attributes))
            }

            cell.setInfo(text, showBeta: true)
        } else {
            cell.setInfo(nil)
        }

        cell.set(UIImage(named: "ico-chain-\(chain.id)"), color: chain.theme.backgroundColor)

        cell.selectionStyle = .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chain = model.models[indexPath.row]
        completion(chain)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLast(path: indexPath) {
            loadNextPage()
        }
    }
}
