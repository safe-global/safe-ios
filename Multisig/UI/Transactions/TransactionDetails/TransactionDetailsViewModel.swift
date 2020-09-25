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

    var canLoadTransaction: Bool {
        hash != nil || id != nil
    }

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
        if canLoadTransaction {
            Just(canLoadTransaction)
                .receive(on: DispatchQueue.global())
                .tryMap { canLoadTransaction -> TransactionViewModel in
                    let transaction = try self.transaction()
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
                        self.errorMessage = error.localizedDescription
                        App.shared.snackbar.show(message: error.localizedDescription)
                    }
                    self.isLoading = false
                    self.isRefreshing = false
                }, receiveValue: { [weak self] transaction in
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

    func transaction() throws -> TransactionDetailsRequest.ResponseType  {
        guard canLoadTransaction else { throw Failure.transactionDetailsNotFound }
        if let hash = hash {
            return try App.shared.clientGatewayService.transactionDetails(safeTxHash: hash)
        } else {
            return try App.shared.clientGatewayService.transactionDetails(id: id!)
        }
    }

    func sign(safeAddress: Address) {
        guard let transferTx = transactionDetails as? TransferTransactionViewModel else { return }
        Just(safeAddress)
            .receive(on: DispatchQueue.global())
            .tryMap { _ in
                try App.shared.safeTransactionService.sign(transaction: transferTx,
                                                           safeAddress: safeAddress)
            }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        App.shared.snackbar.show(message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.reloadData()
                }
            )
            .store(in: &subscribers)
    }
}
