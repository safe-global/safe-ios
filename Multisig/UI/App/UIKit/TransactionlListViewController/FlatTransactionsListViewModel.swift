//
//  FlatTransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 12/14/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct FlatTransactionsListViewModel {
    var items: [SCG.TransactionSummaryItem] = []
    var isEmpty: Bool {
        items.isEmpty
    }

    var next: String?

    init(_ models: [SCG.TransactionSummaryItem] = []) {
        self.items = models
    }

    mutating func append(from list: Self) {
        self.next = list.next
        add(list.items)
    }

    mutating func add(_ models: [SCG.TransactionSummaryItem] = []) {
        self.items.append(contentsOf: models)
    }

    var lastTransaction: SCG.TransactionSummaryItem? {
        items.last
    }
}
