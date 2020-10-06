//
//  LoadingTransactionListView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionsTabView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    @ViewBuilder
    var body: some View {
        if selectedSafe.first != nil {
            LoadingTransactionListView(address: selectedSafe.first?.address)
                .navigationBarTitle("Transactions")
        } else {
            VStack(spacing: 0) {
                AddSafeIntroView().onAppear {
                    self.trackEvent(.assetsNoSafe)
                }
            }
            .navigationBarTitle("Transactions")
        }
    }
}

struct LoadingTransactionListView: View {
    var address: String?
    @EnvironmentObject var model: LoadingTransactionListViewModel
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
            AnotherTransactionListView(list: $model.list, loadMoreStatus: $model.loadMoreStatus, reload: reload, loadMore: loadMore)
        }
    }

    func reload() {
        model.reload()
    }

    func loadMore() {
        model.loadMore()
    }
}

struct AnotherTransactionListView: View {
    @Binding
    var list: TransactionsListViewModel
    @Binding
    var loadMoreStatus: ViewLoadingStatus
    var reload: () -> Void = {}
    var loadMore: () -> Void = {}

    var body: some View {
        List {
            Section {
                ReloadButton(reload: reload)
            }

            ForEach(list.sections) { section in
                Section(header: SectionHeader(section.name)) {
                    ForEach(section.transactions) { transaction in
                        NavigationLink(
                            destination: LoadingTransactionDetailsView(transaction: transaction).navigationBarTitle("Transaction Details", displayMode: .inline)) {
                            TransactionCellView(transaction: transaction)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: Spacing.medium))
                }
            }

            if list.next != nil {
                if loadMoreStatus == .loading {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: loadMore, label: {
                        HStack {
                            Spacer()
                            Text("Load more")
                            Spacer()
                        }
                    })
                    .frame(height: 44)
                    .buttonStyle(GNOPlainButtonStyle())
                }
            }
        }
        .listStyle(GroupedListStyle())
    }

}

import Combine

class LoadingTransactionListViewModel: ObservableObject {
    var list = TransactionsListViewModel()
    @Published
    var status: ViewLoadingStatus = .initial
    @Published
    var loadMoreStatus: ViewLoadingStatus = .initial
    var subscribers = Set<AnyCancellable>()

    let coreDataPublisher = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: App.shared.coreDataStack.viewContext)
        .receive(on: RunLoop.main)

    var reactOnCoreData: AnyCancellable!

    init() {
        reactOnCoreData = coreDataPublisher
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.status = .initial
            }
    }

    func reload() {
        subscribers.removeAll()
        status = .loading
        Just(())
            .tryCompactMap { _ -> String? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe?.address
            }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap { address -> TransactionsListViewModel in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(address: address)
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
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
            }, receiveValue:{ [weak self] value in
                guard let `self` = self else { return }
                self.list = value
            })
            .store(in: &subscribers)
    }

    func loadMore() {
        guard loadMoreStatus != .loading else { return }
        loadMoreStatus = .loading
        Just(list.next)
            .compactMap { $0 }
            .receive(on: DispatchQueue.global())
            .tryMap { url -> TransactionsListViewModel in
                let transactions = try App.shared.clientGatewayService.transactionSummaryList(pageUri: url)
                let models = transactions.results.flatMap { TransactionViewModel.create(from: $0) }
                var list = TransactionsListViewModel(models)
                list.next =  transactions.next
                return list
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.loadMoreStatus = .failure
                } else {
                    self.loadMoreStatus = .success
                }
            }, receiveValue:{ [weak self] value in
                guard let `self` = self else { return }
                self.list.append(from: value)
            })
            .store(in: &subscribers)
    }

}
