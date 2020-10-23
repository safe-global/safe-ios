//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

// Loads and displays balances
class BalancesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    var currentDataTask: URLSessionTask?
    var results: [TokenBalance] = []
    var lastError: Error?

    override var isEmpty: Bool { results.isEmpty }

    let reuseID = "Cell"
    var transactionService = App.shared.safeTransactionService

    static func create() -> BalancesViewController {
        .init(nibName: "\(LoadableViewController.self)", bundle: Bundle(for: LoadableViewController.self))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.register(BalanceTableViewCell.nib(), forCellReuseIdentifier: reuseID)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            // get selected safe
            let context = App.shared.coreDataStack.viewContext
            let fr = Safe.fetchRequest().selected()
            let safe = try context.fetch(fr).first

            // get its address
            guard let string = safe?.address else {
                throw "Selected safe does not have a stored address"
            }
            let address = try Address(from: string)

            currentDataTask = transactionService.asyncSafeBalances(at: address) { [weak self] result in
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
                        self.lastError = error
                        self.onError()
                    }
                case .success(let balances):
                    let results = balances.map(TokenBalance.init)

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.results = results
                        self.onSuccess()
                    }
                }
            }
        } catch {
            lastError = error
            onError()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as! BalanceTableViewCell
        cell.cellMainLabel.text = item.symbol
        cell.cellDetailLabel.text = item.balance
        cell.cellSubDetailLabel.text = item.balanceUsd
        cell.cellImageView.kf.setImage(with: item.imageURL)
        return cell
    }
}
