//
//  CoinBalances.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

enum ViewLoadingStatus {
    case initial, loading, success, failure
}

struct CoinBalancesView: View {
    //  TODO: Tracking
    @EnvironmentObject var model: CoinBalancesModel
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
            BalanceListView(balances: model.balances, reload: reload)
        }
    }

    func reload() {
        model.reload()
    }
}

struct BalanceListView: View {
    var balances: [TokenBalance]
    var reload: () -> Void = {}

    var body: some View {
        List {
            ReloadButton(reload: reload)

            ForEach(balances) { tokenBalance in
                TokenBalanceCell(tokenBalance: tokenBalance)
            }
       }
        .listStyle(GroupedListStyle())

    }
}

struct ReloadButton: View {
    var height: CGFloat = 30
    var iconRotation = Angle(degrees: 135)
    var reload: () -> Void = {}

    var body: some View  {
            Button(action: reload, label: {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.2.circlepath")
                        .rotationEffect(iconRotation)
                    Text("Reload").font(.gnoBody)
                    Spacer()
                }
            })
            .buttonStyle(GNOCustomButtonStyle(color: .gnoMediumGrey))
            .frame(height: height)
    }
}

struct NoDataView: View {
    var reload: () -> Void = {}

    var body: some View {
        VStack {
            ReloadButton(reload: reload)
                .padding(.top, 20)

            HStack {
                Image("ico-server-error")
                Text("Data cannot be loaded").title(.gnoMediumGrey)
            }
            .padding(.top, 115)

            Spacer()
        }
    }
}

struct FullScreenLoadingView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .large)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? {
        self
    }
}

import Combine

class CoinBalancesModel: ObservableObject {
    var balances = [TokenBalance]()
    @Published
    var status: ViewLoadingStatus = .initial
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
            .tryMap { address -> [TokenBalance] in
                let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
                let tokenBalances = balancesResponse.map { TokenBalance($0) }
                return tokenBalances
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
            }, receiveValue:{ [weak self] tokenBalances in
                guard let `self` = self else { return }
                self.balances = tokenBalances
            })
            .store(in: &subscribers)
    }
}
