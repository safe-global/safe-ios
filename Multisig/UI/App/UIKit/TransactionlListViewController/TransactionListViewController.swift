//
//  TransactionListViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionListViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService

    private var loadFirstPageDataTask: URLSessionTask?
    private var loadNextPageDataTask: URLSessionTask?

    private var model = TransactionsListViewModel()

    override var isEmpty: Bool {
        model.isEmpty
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .gnoWhite

        tableView.registerCell(TransactionListTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        tableView.sectionHeaderHeight = BasicHeaderView.headerHeight

        emptyView.setText("Transactions will appear here")
        emptyView.setImage(#imageLiteral(resourceName: "ico-no-transactions"))
    }

    override func reloadData() {
        super.reloadData()
        loadFirstPageDataTask?.cancel()
        loadNextPageDataTask?.cancel()
        stopNextPageLoadingAnimation()

        do {
            let address = try Address(from: try Safe.getSelected()!.address!)

            loadFirstPageDataTask = clientGatewayService.asyncTransactionList(address: address) { [weak self] result in

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
                        self.onError(error)
                    }
                case .success(let page):
                    var model = TransactionsListViewModel(page.results.flatMap { TransactionViewModel.create(from: $0) })
                    model.next = page.next

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.model = model
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(error)
        }
    }

    private func startNextPageLoadingAnimation() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        indicator.frame = CGRect(origin: .zero, size: CGSize(width: tableView.bounds.width, height: 100))
        // moves the indicator up
        indicator.bounds = CGRect(origin: CGPoint(x: 0, y: 30), size: indicator.frame.size)
        tableView.tableFooterView = indicator
    }

    private func stopNextPageLoadingAnimation() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 100))
    }

    private func loadNextPage() {
        // re-entrancy: if loading already, do not cancel and restart
        guard let nextPageUri = model.next, loadNextPageDataTask == nil else { return }

        startNextPageLoadingAnimation()
        do {
            loadNextPageDataTask = try clientGatewayService.asyncTransactionList(pageUri: nextPageUri) { [weak self] result in

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
                        self.onError(error)
                    }
                case .success(let page):
                    var model = TransactionsListViewModel(page.results.flatMap { TransactionViewModel.create(from: $0) })
                    model.next = page.next

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.model.append(from: model)
                        self.onSuccess()
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    self?.stopNextPageLoadingAnimation()
                }

                self.loadNextPageDataTask = nil
            }

        } catch {
            onError(error)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        model.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.sections[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(TransactionListTableViewCell.self, for: indexPath)

        // remove existing controller
        if let vc = cell.controller {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        // add new controller
        let tx = model.sections[indexPath.section].transactions[indexPath.row]
        let vc = UIHostingController(rootView: TransactionCellView(transaction: tx))
        addChild(vc)
        cell.setController(vc)
        vc.didMove(toParent: self)

        // somehow adding hosting controller auto-shows the navigation bar
        navigationController?.navigationBar.isHidden = true

        // if last cell, trigger the loading operation
        if indexPath.section == model.sections.count - 1 &&
            indexPath.row == model.sections[indexPath.section].transactions.count - 1 {
            loadNextPage()
        }
        return cell
    }

    // for getting cell size
    private var cellSizeController: UIHostingController<TransactionCellView>!

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tx = model.sections[indexPath.section].transactions[indexPath.row]

        if cellSizeController == nil {
            cellSizeController = UIHostingController<TransactionCellView>(rootView: TransactionCellView(transaction: tx))
        } else {
            cellSizeController.rootView = TransactionCellView(transaction: tx)
        }
        let size = cellSizeController.sizeThatFits(in: tableView.bounds.size)
        return size.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = model.sections[section]
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(section.name)
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
