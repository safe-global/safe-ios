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
    var reloadSubject = PassthroughSubject<String, Never>()
    var cancellables = Set<AnyCancellable>()
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = TransactionViewModel()

    init() {
        let input = reloadSubject
            .compactMap { TransactionID(value: $0) }

        input
            .status(.loading, path: \.status, object: self, set: &cancellables)

        let output = input
            .receive(on: DispatchQueue.global())
            .tryMap { id -> TransactionViewModel in
                let transaction = try App.shared.clientGatewayService.transactionDetails(id: id)
                let viewModels = TransactionViewModel.create(from: transaction)
                guard viewModels.count == 1, let viewModel = viewModels.first else {
                    throw Failure.unsupportedTransaction
                }
                return viewModel
            }
            .transformToResult()
            .receive(on: RunLoop.main)
            .multicast { PassthroughSubject<Result<TransactionViewModel, Error>, Never>() }

        output
            .handleError(statusPath: \.status, object: self, set: &cancellables)
        output
            .onSuccessResult()
            .status(.success, path: \.status, object: self, set: &cancellables)
        output
            .onSuccessResult()
            .assign(to: \.result, on: self)
            .store(in: &cancellables)

        output
            .connect()
            .store(in: &cancellables)
    }

    func reload(transaction: TransactionViewModel) {
        if transaction is CreationTransactionViewModel {
            result = transaction
            status = .success
        } else {
            reloadSubject.send(transaction.id)
        }
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

}
