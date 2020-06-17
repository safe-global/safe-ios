//
//  TransactionsListViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct TransactionsListViewModel {
    struct Section: Identifiable {
        let id = UUID()
        var name: String
        var transactions: [TransactionViewModel]

        var isEmpty: Bool {
            transactions.isEmpty
        }
    }

    var sections: [Section] = []

    var isEmpty: Bool {
        sections.allSatisfy { $0.isEmpty }
    }

    init(_ models: [TransactionViewModel] = []) {
        var queued = [TransactionViewModel]()
        var history = [TransactionViewModel]()

        for model in models {
            if model.status.isInQueue {
                queued.append(model)
            } else {
                history.append(model)
            }
        }
        sections = [
            Section(name: "QUEUE", transactions: queued),
            Section(name: "HISTORY", transactions: history)
        ].filter { !$0.isEmpty }
    }
}
