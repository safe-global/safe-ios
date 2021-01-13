//
//  FlatTransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 12/14/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct FlatTransactionsListViewModel {
    private var models: [SCGModels.TransactionSummaryItem] = []
    var items: [SCGModels.TransactionSummaryItem] {
        models
    }
    var isEmpty: Bool {
        items.isEmpty
    }

    var next: String?

    init(_ models: [SCGModels.TransactionSummaryItem] = []) {
        self.models = models
    }

    mutating func append(from list: Self) {
        self.next = list.next
        add(list.items)
    }

    mutating func add(_ models: [SCGModels.TransactionSummaryItem] = []) {
        self.models.append(contentsOf: models)
    }

    var lastTransaction: SCGModels.TransactionSummaryItem? {
        models.last
    }
}
