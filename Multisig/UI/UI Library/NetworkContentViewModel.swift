//
//  NetworkContentViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class NetworkContentViewModel: ObservableObject {
    @Published
    var status: ViewLoadingStatus = .initial
    private var subscribers = Set<AnyCancellable>()

    private let coreDataPublisher = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: App.shared.coreDataStack.viewContext)
        .receive(on: RunLoop.main)

    private var coreDataCancellable: AnyCancellable!

    init() {
        coreDataCancellable = coreDataPublisher
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.status = .initial
            }
    }

    func reload<Output>(fetch: @escaping (Safe) throws -> Output, receive: @escaping (Output) -> Void) {
        subscribers.removeAll()
        status = .loading
        Just(())
            .tryCompactMap { _ -> Safe? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe
            }
            .receive(on: DispatchQueue.global())
            .tryMap(fetch)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.status = .failure
                } else {
                    self.status = .success
                }
            }, receiveValue: receive)
            .store(in: &subscribers)
    }

}

