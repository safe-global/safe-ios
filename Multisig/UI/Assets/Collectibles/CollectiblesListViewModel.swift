//
//  CollectiblesViewModel.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class CollectiblesListViewModel: BasicLoadableViewModel {
    struct Section: Identifiable {
        let id = UUID()
        var name: String
        var imageURL: URL?
        var collectibles: [CollectibleViewModel]

        var isEmpty: Bool {
            collectibles.isEmpty
        }
    }
    
    var sections = [Section]()
    private let safe: Safe

    init(safe: Safe) {
        self.safe = safe
        super.init()
    }

    override func reload() {
        Just(safe.address!)
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap { address -> [Section] in
                let collectibles = try App.shared.safeTransactionService.collectibles(at: address)
                let models = Self.createModels(collectibles: collectibles)
                return models
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
            }, receiveValue:{ [weak self] collectibles in
                guard let `self` = self else { return }
                self.sections = collectibles
                self.errorMessage = nil
            })
            .store(in: &subscribers)
    }

    private static func createModels(collectibles: [Collectible]) -> [Section] {
        let groupedCollectibles = Dictionary(grouping: collectibles, by: { $0.address })
        return groupedCollectibles.map { (key, value) in
            let token = App.shared.tokenRegistry[key!.address]
            let name = token?.name ?? "Unknown"
            let logoURL = token?.logo
            let collectibles = value.compactMap { CollectibleViewModel(collectible: $0) }.sorted { $0.name < $1.name }
            
            return Section(name: name , imageURL: logoURL, collectibles: collectibles)
        }.sorted { $0.name < $1.name }
    }
}
