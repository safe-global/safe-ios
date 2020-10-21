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
                    // because this operation will take some time
                    // we'll check if the transaction id haven't changed
                    let model = try self.loadContent(id: transaction.id)
                    DispatchQueue.main.async {
                        self.result = model
                        self.status = .success
                    }
                } catch {
                    DispatchQueue.main.async {
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
        let viewModels = TransactionViewModel.create(from: transaction)
        guard viewModels.count == 1, let viewModel = viewModels.first else {
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
        DispatchQueue.global().async {
            do {
                try App.shared.safeTransactionService.sign(transaction: transaction, safeAddress: address)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                    self.status = .initial
                }
            } catch {
                DispatchQueue.main.async {
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
