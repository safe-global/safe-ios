//
//  LoadingTransactionDetailsViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class LoadingTransactionDetailsViewModel: ObservableObject {

    // input: the model will load details by id
    var id: TransactionID?
    // default output
    var transactionDetails: TransactionViewModel = TransactionViewModel()

    @Published
    var status: ViewLoadingStatus = .initial

    var subscribers = Set<AnyCancellable>()

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

    func reload(transaction: TransactionViewModel) {
        guard status != .loading else { return }
        if transaction is CreationTransactionViewModel {
            transactionDetails = transaction
            self.status = .success
        } else {
            id = TransactionID(value: transaction.id)
            status = .loading

            Just(id)
                .compactMap { $0 }
                .receive(on: DispatchQueue.global())
                .tryMap { id -> TransactionViewModel in
                    let transaction = try App.shared.clientGatewayService.transactionDetails(id: id)
                    let viewModels = TransactionViewModel.create(from: transaction)
                    guard viewModels.count == 1, let viewModel = viewModels.first else {
                        throw Failure.unsupportedTransaction
                    }
                    return viewModel
                }
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let `self` = self else { return }
                    if case .failure(let error) = completion {
                        App.shared.snackbar.show(message: error.localizedDescription)
                        self.status = .failure
                    } else {
                        self.status = .success
                    }
                }, receiveValue:{ [weak self] transaction in
                    guard let `self` = self else { return }
                    self.transactionDetails = transaction
                })
                .store(in: &subscribers)

        }
    }

}
