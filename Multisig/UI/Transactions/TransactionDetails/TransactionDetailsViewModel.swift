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
    var hash: Data?
    var id: TransactionID?
    
    var transactionDetails: TransactionViewModel = TransactionViewModel()

    init(transaction: TransactionViewModel) {
        id = TransactionID(value: transaction.id)
        super.init()
        reloadData()
    }

    init(hash: String) {
        self.hash = Data(hex: hash)

        super.init()
        reloadData()
    }

    enum Failure: LocalizedError {
        case transactionDetailsNotFound, unsupportedTransaction
        var errorDescription: String? {
            switch self {
            case .transactionDetailsNotFound:
                return "Information about this transaction can't be loaded"
            case .unsupportedTransaction:
                return "Information about this transaction type is not supported"
            }
        }
    }

    override func reload() {
        if let hash = hash {
            Just(hash)
                .compactMap { $0 }
                .setFailureType(to: Error.self)
                .flatMap { hash in
                    Future<TransactionViewModel, Error> { promise in
                        DispatchQueue.global().async {
                            do {
                                let transaction = try App.shared.clientGatewayService.transactionDetails(safeTxHash: hash)
                                let viewModels = TransactionViewModel.create(from: transaction)
                                guard viewModels.count == 1, let viewModel = viewModels.first else {
                                    promise(.failure(Failure.unsupportedTransaction))
                                    return
                                }
                                promise(.success(viewModel))
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
                    self.transactionDetails = transaction
                    self.errorMessage = nil
                })
                .store(in: &subscribers)
        } else if let id = id {
            Just(id)
            .setFailureType(to: Error.self)
            .flatMap { id in
                Future<TransactionViewModel, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let transaction = try App.shared.clientGatewayService.transactionDetails(id: id)
                            let viewModels = TransactionViewModel.create(from: transaction)
                            guard viewModels.count == 1, let viewModel = viewModels.first else {
                                promise(.failure(Failure.unsupportedTransaction))
                                return
                            }
                            promise(.success(viewModel))
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
                self.transactionDetails = transaction
                self.errorMessage = nil
            })
            .store(in: &subscribers)
        } else {
            self.errorMessage = Failure.transactionDetailsNotFound.localizedDescription
            self.isLoading = false
            self.isRefreshing = false
        }
    }
}
