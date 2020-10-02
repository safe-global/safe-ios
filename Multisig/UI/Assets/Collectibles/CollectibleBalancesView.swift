//
//  CollectibleBalancesView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectibleBalancesView: View {
    var address: String?
    @ObservedObject var model = CollectibleBalancesModel()
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
            CollectibleListView(sections: model.sections, reload: reload)
        }
    }

    func reload() {
        model.reload(address: address)
    }
}

typealias CollectibleListSection = CollectiblesListViewModel.Section

struct CollectibleListView: View {
    var sections: [CollectibleListSection]
    var reload: () -> Void = {}

    var body: some View {
        List {
            ReloadButton(reload: reload)

            ForEach(sections) { section in
                CollectiblesSectionView(section: section)
            }
       }
        .listStyle(GroupedListStyle())

    }
}

import Combine

class CollectibleBalancesModel: ObservableObject {
    var sections = [CollectibleListSection]()
    @Published
    var status: ViewLoadingStatus = .initial
    var subscribers = Set<AnyCancellable>()

    func reload(address: String?) {
        guard status != .loading else { return }
        status = .loading
        Just(address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap { address -> [CollectibleListSection] in
                let collectibles = try App.shared.safeTransactionService.collectibles(at: address)
                let models = CollectibleListSection.create(collectibles)
                return models
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
            }, receiveValue:{ [weak self] values in
                guard let `self` = self else { return }
                self.sections = values
            })
            .store(in: &subscribers)
    }
}

extension CollectibleListSection {
    static func create(_  collectibles: [Collectible]) -> [Self] {
        let groupedCollectibles = Dictionary(grouping: collectibles, by: { $0.address })
        return groupedCollectibles.map { (key, value) in
            let token = App.shared.tokenRegistry[key!.address]
            let name = token?.name ?? "Unknown"
            let logoURL = token?.logo
            let collectibles = value.compactMap { CollectibleViewModel(collectible: $0) }.sorted { $0.name < $1.name }

            return Self.init(name: name , imageURL: logoURL, collectibles: collectibles)
        }.sorted { $0.name < $1.name }
    }
}
