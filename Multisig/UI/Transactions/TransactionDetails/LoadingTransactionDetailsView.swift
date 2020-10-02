//
//  LoadingTransactionDetailsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 02.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

struct LoadingTransactionDetailsView: View {
    var transaction: TransactionViewModel

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    private var selectedSafe: FetchedResults<Safe>

    @ObservedObject var model: LoadingTransactionDetailsViewModel

    var status: ViewLoadingStatus { model.status }

    @ViewBuilder
    var body: some View {
        if status == .initial {
            Text("Loading...").onAppear(perform: reload)
        } else if status == .loading {
            FullScreenLoadingView()
        } else if status == .failure {
            NoDataView(reload: reload)
        } else if status == .success {
            TransactionDetailsOuterBodyView(transactionModel: model.transactionDetails, safe: selectedSafe.first!, reload: reload)
        }
    }

    func reload() {
        model.reload(transaction: transaction)
    }
}

extension LoadingTransactionDetailsView {
    init(transaction: TransactionViewModel) {
        self.transaction = transaction
        model = AppViewModel.shared.details(transaction)
    }
}


struct TransactionDetailsOuterBodyView: View {
    var transactionModel: TransactionViewModel
    var safe: Safe
    var reload: () -> Void = { }
    var body: some View {
        List {
            ReloadButton(reload: reload)

            if transactionModel is CreationTransactionViewModel {
                CreationTransactionBodyView(transaction: transactionModel as! CreationTransactionViewModel)
            } else {
                TransactionDetailsInnerBodyView(transactionModel: transactionModel, safe: safe)
            }

            if transactionModel.browserURL != nil {
                viewTxOnEtherscan
            }
        }
        .navigationBarTitle("Transaction Details", displayMode: .inline)
    }



    @State
    private var showsLink: Bool = false
    private let padding: CGFloat = 11

    private var viewTxOnEtherscan: some View {
        Button(action: { self.showsLink.toggle() }) {
            LinkText(title: "View transaction on Etherscan")
        }
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.gnoHold)
        .sheet(isPresented: $showsLink, content: browseTransaction)
        .padding(.vertical, padding)
    }

    private func browseTransaction() -> some View {
        SafariViewController(url: transactionModel.browserURL!)
    }
}


struct TransactionDetailsInnerBodyView: View {
    var transactionModel: TransactionViewModel
    var safe: Safe

    private let padding: CGFloat = 11

    private var dataDecoded: DataDecoded? {
        guard let customTransaction = transactionModel as? CustomTransactionViewModel else {
            return nil
        }

        return customTransaction.dataDecoded
    }

    private var displayConfirmations: Bool {
        guard let transferTransaction = transactionModel as? TransferTransactionViewModel else {
            return true
        }

        return transferTransaction.isOutgoing
    }

    private var data: (length: UInt256, data: String)? {
        guard let customTransaction = transactionModel as? CustomTransactionViewModel,
              let data = customTransaction.data else {
            return nil
        }

        return (length: customTransaction.dataLength, data: data)
    }

    var body: some View {
        Group {
            TransactionHeaderView(transaction: transactionModel)

            if dataDecoded != nil {
                TransactionActionView(dataDecoded: dataDecoded!)
            }

            if data != nil {
                VStack (alignment: .leading) {
                    Text("Data").headline()
                    ExpandableButton(title: "\(data!.length) Bytes", value: data!.data)
                }.padding(.vertical, padding)
            }

            TransactionStatusTypeView(transaction: transactionModel)
            if displayConfirmations {
                TransactionConfirmationsView(transaction: transactionModel, safe: safe).padding(.vertical, padding)
            }

            if transactionModel.formattedCreatedDate != nil {
                KeyValueRow("Created:",
                            value: transactionModel.formattedCreatedDate!,
                            enableCopy: false,
                            color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transactionModel.formattedExecutedDate != nil {
                KeyValueRow("Executed:",
                            value: transactionModel.formattedExecutedDate!,
                            enableCopy: false,
                            color: .gnoDarkGrey).padding(.vertical, padding)
            }

            if transactionModel.hasAdvancedDetails {
                NavigationLink(destination: AdvancedTransactionDetailsView(transaction: transactionModel)) {
                    Text("Advanced").body()
                }
                .frame(height: 48)
            }
        }
    }
}

class LoadingTransactionDetailsViewModel: ObservableObject {

    // input; will load details
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
