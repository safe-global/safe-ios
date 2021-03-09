//
//  OwnerKeysListViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/9/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OwnerKeysListViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .primaryBackground

        tableView.registerCell(OwnerKeysListTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setText("There are no imported owner keys")
        emptyView.setImage(#imageLiteral(resourceName: "ico-no-keys"))

        notificationCenter.addObserver(
            self,
            selector: #selector(lazyReloadData),
            name: .transactionDataInvalidated,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerKeysList)
    }

    override func reloadData() {
        super.reloadData()

//        do {
//            let address = try Address(from: try Safe.getSelected()!.address!)
//
//            loadFirstPageDataTask = asyncTransactionList(address: address) { [weak self] result in
//                guard let `self` = self else { return }
//                switch result {
//                case .failure(let error):
//                    DispatchQueue.main.async { [weak self] in
//                        guard let `self` = self else { return }
//                        // ignore cancellation error due to cancelling the
//                        // currently running task. Otherwise user will see
//                        // meaningless message.
//                        if (error as NSError).code == URLError.cancelled.rawValue &&
//                            (error as NSError).domain == NSURLErrorDomain {
//                            return
//                        }
//                        self.onError(GSError.error(description: "Failed to load transactions", error: error))
//                    }
//                case .success(let page):
//                    var model = FlatTransactionsListViewModel(page.results)
//                    model.next = page.next
//
//                    DispatchQueue.main.async { [weak self] in
//                        guard let `self` = self else { return }
//                        self.model = model
//                        self.onSuccess()
//                    }
//                }
//            }
//        } catch {
//            onError(GSError.error(description: "Failed to load transactions", error: error))
//        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(table: tableView, indexPath: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
