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
    private let appSettings: AppSettings = AppSettings.current()
    let safe = Selection.current().safe!
    var hash: Data?
    var id: TransactionID?
    var transactionDetails: TransactionViewModel = TransactionViewModel()

    private var signingKeyAddress: String? {
        return appSettings.signingKeyAddress
    }

    var canSign: Bool {
        transactionDetails.status == .awaitingConfirmations &&
            signingKeyAddress != nil &&
            transactionDetails.signers!.contains(signingKeyAddress!) &&
            !transactionDetails.confirmations!.map { $0.address }.contains(signingKeyAddress!)
    }

    var canLoadTransaction: Bool {
        hash != nil || id != nil
    }

    init(transaction: TransactionViewModel) {
        super.init()
        if transaction is CreationTransactionViewModel {
            transactionDetails = transaction
            self.isLoading = false
            self.isRefreshing = false
        } else {
            id = TransactionID(value: transaction.id)
            reloadData()
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

    func sign() {
        guard let transferTx = transactionDetails as? TransferTransactionViewModel,
              let transaction = transferTx.transaction else {
            assertionFailure("We have a technical problem. You need to restart the app.")
            return
        }
        Just(safe.address!)
            .receive(on: DispatchQueue.global())
            .tryMap { address in
                try App.shared.safeTransactionService.sign(transaction: transaction, safeAddress: Address(address)!)
            }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        App.shared.snackbar.show(message: error.localizedDescription)
                        guard let `self` = self else { return }
                        LogService.shared.error("Could not sign a transaction for safe: \(self.safe.address!)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.reloadData()
                }
            )
            .store(in: &subscribers)
    }
}
