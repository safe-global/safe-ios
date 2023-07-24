//
//  CollectiblesViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class CollectiblesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService
    let rowHeight: CGFloat = 160
    let headerHeight: CGFloat = 52
    let footerHeight: CGFloat = 13
    let tableBackgroundColor: UIColor = .backgroundPrimary

    private var loadFirstPageDataTask: URLSessionTask?
    private var loadNextPageDataTask: URLSessionTask?

    private var model = FlatCollectiblesListViewModel()

    internal var safe: Safe!

    var sections = [CollectibleListSection]()

    override var isEmpty: Bool { model.isEmpty }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = UIColor(named: "backgroundContent")

        tableView.registerCell(CollectibleTableViewCell.self)
        tableView.registerCell(CollectibleHeaderTableViewCell.self)

        tableView.registerHeaderFooterView(IdleFooterView.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.registerHeaderFooterView(RetryFooterView.self)

        tableView.sectionHeaderHeight = headerHeight
        tableView.sectionFooterHeight = footerHeight
        tableView.separatorStyle = .none
        emptyView.setTitle("Collectibles will appear here")
        emptyView.setImage(UIImage(named: "ico-no-collectibles")!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsCollectibles)
    }

    override func reloadData() {
        super.reloadData()

        loadFirstPageDataTask?.cancel()
        loadNextPageDataTask?.cancel()
        pageLoadingState = .idle

        loadFirstPageDataTask = asyncCollectiblesList { [weak self] result in
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
                    self.onError(GSError.error(description: "Failed to load collectibles", error: error))
                }
            case .success(let page):
                var model = FlatCollectiblesListViewModel(page.results)
                model.next = page.next

                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }

                    self.model = model
                    self.onSuccess()
                }
            }
        }
    }

    private func loadNextPage() {
        // re-entrancy: if loading already, do not cancel and restart
        guard let nextPageUri = model.next, loadNextPageDataTask == nil else { return }

        pageLoadingState = .loading
        do {
            loadNextPageDataTask = try asyncCollectiblesList(pageUri: nextPageUri) { [weak self] result in
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
                        self.onError(GSError.error(description: "Failed to load more collectibles", error: error))
                        self.pageLoadingState = .retry
                    }
                case .success(let page):
                    var model = FlatCollectiblesListViewModel(page.results)
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
            onError(GSError.error(description: "Failed to load more collectibles", error: error))
            pageLoadingState = .retry
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

    func asyncCollectiblesList(
        completion: @escaping (Result<Page<Collectible>, Error>) -> Void) -> URLSessionTask? {
        safe = try! Safe.getSelected()!
        return clientGatewayService.asyncCollectiblesList(safeAddress: safe.addressValue,
                                                                        chainId: safe.chain!.id!,
                                                                        completion: completion)
    }

    func asyncCollectiblesList(pageUri: String, completion: @escaping (Result<Page<Collectible>, Error>) -> Void) throws -> URLSessionTask? {
        clientGatewayService.asyncExecute(request: try PagedRequest<Collectible>(pageUri), completion: completion)
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = CGFloat()
        let item = model.items[indexPath.row]
        switch item {
        case .header:
            height = 50
        case .collectible:
            height = 150
        }
        return height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(table: tableView, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLast(path: indexPath) {
            loadNextPage()
        }
    }

    private func isLast(path: IndexPath) -> Bool {
        path.row == model.items.count - 1
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = model.items[indexPath.row]
        switch item {
        case .collectible(let collectibleItem):
            let collectible = collectibleItem.collectible
            let root = CollectibleDetailViewController(nibName: nil, bundle: nil)
            root.collectible = CollectibleViewModel(collectible: collectible)
            let vc = RibbonViewController(rootViewController: root)
            show(vc, sender: self)
        case .header(_):
            break
        }
    }

    func cell(table: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let item = model.items[indexPath.row]

        switch item {
        case .header(let collectibleHeader):
            let cell = tableView.dequeueCell(CollectibleHeaderTableViewCell.self, for: indexPath)
            cell.setName(collectibleHeader.name)
            cell.setImage(with: collectibleHeader.logoURL, placeholder: UIImage(named: "ico-nft-placeholder")!)
            cell.selectionStyle = .none
            return cell
        case .collectible(let collectibleItem):
            let cell = tableView.dequeueCell(CollectibleTableViewCell.self, for: indexPath)
            cell.setName(collectibleItem.collectible.name ?? "Unknown")
            cell.setDescription(collectibleItem.collectible.description ?? "")
            cell.setImage(with: URL(string: collectibleItem.collectible.imageUri ?? ""), placeholder: UIImage(named: "ico-collectible-placeholder")!)
            return cell
        }
    }
}
