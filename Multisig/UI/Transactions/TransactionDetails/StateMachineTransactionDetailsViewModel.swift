//
//  StateMachineTransactionDetailsViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class StateMachineTransactionDetailsViewModel: ObservableObject {

    @Published var status: ViewLoadingStatus = .initial
    @Published var result = TransactionViewModel()

    var canSign: Bool {
        result.status == .awaitingYourConfirmation && result.transaction != nil
    }

    func reload(transaction: TransactionViewModel) {
        if transaction is CreationTransactionViewModel {
            result = transaction
            status = .success
        } else {
            status = .loading
            DispatchQueue.global().async { [weak self] in
                guard let `self` = self else { return }
                do {
                    let model = try self.loadContent(id: transaction.id)
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.result = model
                        self.status = .success
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        App.shared.snackbar.show(message: error.localizedDescription)
                        self.status = .failure
                    }
                }
            }
        }
    }

    func loadContent(id idString: String) throws -> TransactionViewModel {
        let id = TransactionID(value: idString)
        let transaction = try App.shared.clientGatewayService.transactionDetails(id: id)
        let result = try viewModel(from: transaction)
        return result
    }

    func viewModel(from details: TransactionDetails) throws -> TransactionViewModel {
        let modelList = TransactionViewModel.create(from: details)
        guard modelList.count == 1, let viewModel = modelList.first else {
            throw LoadingTransactionDetailsFailure.unsupportedTransaction
        }
        return viewModel
    }

    func sign() {
        guard let transaction = result.transaction,
              let string = Selection.current().safe?.address,
              let address = Address(string) else {
            App.shared.snackbar.show(message: "Can't sign this transaction")
            return
        }
        status = .loading
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            do {
                let signature = try SafeTransactionSigner().sign(transaction, by: address)
                let safeTxHash = transaction.safeTxHash!.description
                let details = try App.shared.clientGatewayService.confirm(safeTxHash: safeTxHash, with: signature.value)
                let model = try self.viewModel(from: details)
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.result = model
                    self.status = .success
                    App.shared.snackbar.show(message: "Confirmation successfully submitted")
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.status = .failure
                }
            }
        }
    }

}

enum LoadingTransactionDetailsFailure: LocalizedError {
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
