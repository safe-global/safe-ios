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
    var signSubject = PassthroughSubject<Transaction, Never>()
    var cancellables = Set<AnyCancellable>()
    var signCancellables = Set<AnyCancellable>()
    @Published var status: ViewLoadingStatus = .initial
    @Published var result = TransactionViewModel()

    init() {
        buildReloadPipeline()
        buildSignPipeline()
    }

    func buildReloadPipeline() {
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

    func buildSignPipeline() {
        signSubject
            .status(.loading, path: \.status, object: self, set: &signCancellables)

        let output = signSubject
            .compactMap { transaction in
                guard let string = Selection.current().safe?.address,
                      let address = Address(string) else { return nil }
                return (address, transaction)
            }
            .receive(on: DispatchQueue.global())
            .tryMap { (address, transaction) -> Void in
                try App.shared.safeTransactionService.sign(transaction: transaction, safeAddress: address)
            }
            .delay(for: .milliseconds(1500), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .transformToResult()
            .multicast { PassthroughSubject<Result<Void, Error>, Never>() }

        output
            .handleError(statusPath: \.status, object: self, set: &signCancellables)

        output
            .onSuccessResult()
            .status(.initial, path: \.status, object: self, set: &signCancellables)

        output
            .connect()
            .store(in: &signCancellables)
    }

    func reload(transaction: TransactionViewModel) {
        if transaction is CreationTransactionViewModel {
            result = transaction
            status = .success
        } else {
            self.cancellables = .init()
            self.reloadSubject = .init()
            self.buildReloadPipeline()
            reloadSubject.send(transaction.id)
        }
    }

    var canSign: Bool {
        result.status == .awaitingYourConfirmation
    }

    func sign() {
        guard let transferTx = result as? TransferTransactionViewModel,
              let transaction = transferTx.transaction else {
            preconditionFailure(
                "Failed to sign: either transaction is not a transfer or the internal transaction does not exist.")
        }
        self.signCancellables = .init()
        self.signSubject = .init()
        self.buildSignPipeline()
        signSubject.send(transaction)
    }
}

extension LoadingTransactionDetailsViewModel {
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
