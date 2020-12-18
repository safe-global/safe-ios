//
//  QueuedTransactionsViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class QueuedTransactionsViewController: TransactionListViewController {
    private weak var timer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        trackingEvent = .transactionsQueued
        // Do any additional setup after loading the view.
        startTimer()
    }
    
    override func asyncTransactionList(address: Address, completion: @escaping (Result<Page<SCG.TransactionSummaryItem>, Error>) -> Void) -> URLSessionTask? {
        clientGatewayService.asyncExecute(request: QueuedTransactionsSummaryListRequest(address), completion: completion)
    }

    override func asyncTransactionList(pageUri: String, completion: @escaping (Result<Page<SCG.TransactionSummaryItem>, Error>) -> Void) throws -> URLSessionTask? {
        clientGatewayService.asyncExecute(request: try PagedRequest<SCG.TransactionSummaryItem>(pageUri), completion: completion)
    }

    @objc func updateScreen() {
        tableView.reloadData()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(updateScreen), userInfo: nil, repeats: true)    }

    func stopTimer() {
        timer?.invalidate()
    }

    override func formatted(date: Date) -> String {
        date.timeAgo()
    }

    deinit {
        stopTimer()
    }
}


extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
