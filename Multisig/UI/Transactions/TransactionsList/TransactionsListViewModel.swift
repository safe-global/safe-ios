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

    var next: String?

    private var allSections: [Section] = []

    var sections: [Section] {
        allSections.filter { !$0.isEmpty }
    }

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

        allSections = [
           Section(name: "QUEUE", transactions: queued),
           Section(name: "HISTORY", transactions: history)
        ]
    }

    mutating func append(from list: Self) {
        self.next = list.next
        self.allSections[0].transactions.append(contentsOf: list.allSections[0].transactions)
        self.allSections[1].transactions.append(contentsOf: list.allSections[1].transactions)
    }

    mutating func add(_ models: [TransactionViewModel] = []) {
       for model in models {
           if model.status.isInQueue {
               allSections[0].transactions.append(model)
           } else {
               allSections[1].transactions.append(model)
           }
       }
    }

    var lastTransaction: TransactionViewModel? {
        sections.last?.transactions.last
    }
}
