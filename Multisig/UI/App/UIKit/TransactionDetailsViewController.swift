//
//  TransactionDetailsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionDetailsViewController: LoadableViewController, UITableViewDataSource, UITableViewDelegate {
    var clientGatewayService = App.shared.clientGatewayService

    private var cells: [UITableViewCell] = []
    private var transaction: TransactionViewModel?
    private var reloadDataTask: URLSessionTask?

    private enum TransactionSource {
        case id(String)
        case safeTxHash(Data)
        case data(TransactionViewModel)
    }

    private var txSource: TransactionSource!

    // disable reacting to change of safes reactsToSelectedSafeChanges
    override var reactsToSelectedSafeChanges: Bool { false }

    convenience init(transactionID: String) {
        self.init(namedClass: Self.superclass())
        txSource = .id(transactionID)
    }

    convenience init(safeTxHash: Data) {
        self.init(namedClass: Self.superclass())
        txSource = .safeTxHash(safeTxHash)
    }

    convenience init(transaction: TransactionViewModel) {
        self.init(namedClass: Self.superclass())
        txSource = .data(transaction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
    }

    override func reloadData() {
        super.reloadData()
        reloadDataTask?.cancel()

        let loadingCompletion: (Result<TransactionDetails, Error>) -> Void = { [weak self] result in
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
            case .success(let details):
                guard let model = TransactionViewModel.create(from: details).first else {
                    self.onError(LoadingTransactionDetailsFailure.unsupportedTransaction)
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.recreateCells(from: model)
                    self.onSuccess()
                }
            }
        }

        switch txSource {
        case .id(let txID):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(id: TransactionID(value: txID), completion: loadingCompletion)
        case .safeTxHash(let safeTxHash):
            reloadDataTask = clientGatewayService.asyncTransactionDetails(safeTxHash: safeTxHash, completion: loadingCompletion)
        case .data(let tx):
            recreateCells(from: tx)
            onSuccess()
        case .none:
            preconditionFailure("Developer error: txSource is required")
        }
    }

    func recreateCells(from transaction: TransactionViewModel?) {
        self.transaction = transaction
        cells = []
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

}
