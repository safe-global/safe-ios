//
//  HistoryTransactionsViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class HistoryTransactionsViewController: TransactionListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        trackingEvent = .transactionsHistory

        timeFormatter = {
            let d = DateFormatter()
            d.locale = .autoupdatingCurrent
            // time offset is 0 here because server returns adjusted dates in the specified client's time zone
            d.timeZone = TimeZone(secondsFromGMT: 0)
            d.dateStyle = .none
            d.timeStyle = .short
            return d
        }()

        dateFormatter = {
            let d = DateFormatter()
            d.locale = .autoupdatingCurrent
            // time offset is 0 here because server returns adjusted dates in the specified client's time zone
            d.timeZone = TimeZone(secondsFromGMT: 0)
            d.dateStyle = .medium
            d.timeStyle = .none
            return d
        }()

        notificationCenter.addObserver(
            self,
            selector: #selector(lazyReloadData),
            name: .incommingTxNotificationReceived,
            object: nil)
    }

    override func asyncTransactionList(
        completion: @escaping (Result<Page<SCGModels.TransactionSummaryItem>, Error>) -> Void) -> URLSessionTask? {
        safe = try! Safe.getSelected()!
        return clientGatewayService.asyncHistoryTransactionsSummaryList(safeAddress: safe.addressValue,
                                                                        chainId: safe.chain!.id!,
                                                                        completion: completion)
    }

    override func asyncTransactionList(pageUri: String, completion: @escaping (Result<Page<SCGModels.TransactionSummaryItem>, Error>) -> Void) throws -> URLSessionTask? {
        clientGatewayService.asyncExecute(request: try PagedRequest<SCGModels.TransactionSummaryItem>(pageUri), completion: completion)
    }
}
