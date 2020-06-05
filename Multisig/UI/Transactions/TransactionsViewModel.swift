//
//  TransactionListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import SwiftCryptoTokenFormatter
import BigInt

struct TransactionsList {
    struct Section {
        var name: String
        var transactions: [BaseTransactionViewModel]
    }

    var sections: [Section] = []

    var isEmpty: Bool {
        sections.allSatisfy { $0.transactions.isEmpty }
    }
}

class BaseTransactionViewModel {

    var nonce: String?
    var status: TransactionStatus
    var formattedDate: String
    var confirmationCount: Int?
    var threshold: Int?

    init() {
        self.status = .success
        self.formattedDate = ""
    }
}


class TransferTransaction: BaseTransactionViewModel {

    var address: String
    var isOutgoing: Bool
    var amount: String
    var tokenSymbol: String

    override init() {
        self.amount = "0"

        self.tokenSymbol = "ETH"
        isOutgoing = true
        address = ""
        super.init()
    }
}


class ChangeMasterCopyTransaction: BaseTransactionViewModel {

    var contractVersion: String
    var contractAddress: String

    override init() {
        contractVersion = ""
        contractAddress = ""
        super.init()
    }
}


class SettingChangeTransaction: BaseTransactionViewModel {

    var title: String

    override init() {
        title = ""
    }

}

class CustomTransaction: TransferTransaction {
    var dataLength: Int

    override init() {
        dataLength  = 98
        super.init()
    }
}


//func cellForModel(_ m: BaseTransactionViewModel) {
//    switch m {
//    case let x as CustomTransaction:
//        OneCell(x)
//        break
//
//    case let x as CustomTransaction:
//        OtherCell(x)
//        break
//
//        case let x as CustomTransaction:
//        break
//    }
//}



class TransactionsViewModel: ObservableObject {
    @Published var transactionsList = TransactionsList()

    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil


    private let safe: Safe
    private var subscribers = Set<AnyCancellable>()

    init(safe: Safe) {
        self.safe = safe
        loadData()
    }

    func loadData() {
        isLoading = true
        Just(safe.address!)
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<TransactionsList, Error> { promise in
                    DispatchQueue.global().async {
                        do {

                            let info = try App.shared.safeTransactionService.safeInfo(at: address)
                            let transactions = try App.shared.safeTransactionService.transactions(address: address)

                            let models = transactions.results.flatMap { self.viewModel(from: $0, info) }

                            promise(.success(TransactionsList()))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue:{ transactionsList in
                self.transactionsList = transactionsList
            })
            .store(in: &subscribers)
    }

    func viewModel(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [BaseTransactionViewModel] {
        switch tx.txType {
        case .some(.module):
            return []
        case .some(.ethereum):
            return transfers(from: tx, info)
        case .some(.multiSig):
            return [multisigTx(from: tx, info)]
        default:
            return []
        }
    }

    func transfers(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [BaseTransactionViewModel] {
        return []
    }

    func multisigTx(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel {
        fatalError()
    }

}
