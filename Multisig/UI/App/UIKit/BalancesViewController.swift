//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class BalancesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    // store current data task
    var currentDataTask: URLSessionTask?

    // store the results
    var results: [TokenBalance] = []
    var lastError: Error?

    // isEmpty { results.isEmpty }
    override var isEmpty: Bool { results.isEmpty }

    let reuseID = "Cell"
    var transactionService = App.shared.safeTransactionService

    // viewDidLoad
    //      tableView data source, delegate = self

    static func create() -> BalancesViewController {
        .init(nibName: "\(LoadableViewController.self)", bundle: Bundle(for: LoadableViewController.self))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // empty view customization
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        // register cell
        tableView.register(BalanceTableViewCell.nib(), forCellReuseIdentifier: reuseID)
    }

    // TODO: start twice
    override func reloadData() {
        super.reloadData()
        // cancel current task;
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

            // task = load balances async
            currentDataTask = transactionService.asyncSafeBalances(at: address) { [weak self] result in
                guard let `self` = self else { return }
                //      error -> onError (main thread)
                //      success -> transform; onSuccess (main thread)
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error!
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

    // number of rows
    //      results.count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    // cell for row
    //      balance cell
    //      data = item[indexPath.row]
    //      cell.setData(image, symbol, token balance, fiat balance)
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
