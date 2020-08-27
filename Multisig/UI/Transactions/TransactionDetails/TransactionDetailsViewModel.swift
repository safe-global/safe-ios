//
//  TransactionDetailsViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class TransactionDetailsViewModel: BasicLoadableViewModel {
    var transaction: TransactionDetailsViewModel?
    var hash: Data?

    init(transaction: TransactionDetailsViewModel) {
        self.transaction = transaction
        super.init()
        isLoading = false
        isRefreshing = false
        if let hash = transaction.safeHash {
            self.hash = Data(hex: hash)
        } else {
            isRefreshingEnabled = false
        }
    }

    init(hash: String) {
        self.transaction = nil
        self.hash = Data(hex: hash)
        super.init()
        reloadData()
    }

    enum Failure: LocalizedError {
        case safeInfoMissing, unsupportedTransaction

        var errorDescription: String? {
            switch self {
            case .safeInfoMissing:
                return "No more info available for this transaction"
            case .unsupportedTransaction:
                return "Information about this transaction type is not supported"
            }
        }
    }

    override func reload() {
        guard isRefreshingEnabled else { return }
        Just(hash)
            .compactMap { $0 }
            .setFailureType(to: Error.self)
            .flatMap { hash in
                Future<TransactionViewModel, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let transaction = try App.shared.safeTransactionService.transaction(hash: hash)
                            guard let safe = transaction.safe?.address else {
                                promise(.failure(Failure.safeInfoMissing))
                                return
                            }
                            let safeInfo = try App.shared.safeTransactionService.safeInfo(at: safe)
                            let models = TransactionViewModel.create(from: transaction, safeInfo)
                            guard models.count == 1, let model = models.first else {
                                promise(.failure(Failure.unsupportedTransaction))
                                return
                            }
                            promise(.success(model))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    App.shared.snackbar.show(message: error.localizedDescription)
                }
                self.isLoading = false
                self.isRefreshing = false
            }, receiveValue:{ [weak self] transaction in
                guard let `self` = self else { return }
                self.transaction = transaction
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }

}

extension TransactionDetailsViewModel {

    static func create(from tx: TransactionDetails, _ info: SafeStatusRequest.Response) -> TransactionDetailsViewModel {
        // ask each class to create view models
        // and take the first recognized result
        [
            TransferTransactionViewModel.self,
            SettingChangeTransactionViewModel.self,
            ChangeImplementationTransactionViewModel.self,
            CustomTransactionViewModel.self
        ]
        .map { $0.viewModels(from: tx, info: info) }
        .first { !$0.isEmpty }
        ?? []
    }

}
