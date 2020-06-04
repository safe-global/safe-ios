//
//  LoadableSafeSettingsViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/6/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine
import CoreData

class LoadableSafeSettingsViewModel: NSObject, ObservableObject {
    @Published
    var isLoading: Bool = true

    @Published
    var errorMessage: String?

    @Published
    private(set) var safe: Safe?

    private let fetchResultsController: NSFetchedResultsController<Safe>
    private var lastUpdatedAddress: String?
    private var subscribers = Set<AnyCancellable>()

    override init() {
        fetchResultsController = NSFetchedResultsController(fetchRequest: Safe.fetchRequest().selected(),
                                                            managedObjectContext: App.shared.coreDataStack.viewContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        super.init()
        fetchResultsController.delegate = self
        try! fetchResultsController.performFetch()
        // after performFetch the delegate method 'controllerDidChangeContent' is not triggered,
        // so we need to trigger update here
        if let safe = fetchResultsController.fetchedObjects?.first {
            self.safe = safe
            updateOnce(safe)
        }
    }

    private func updateOnce(_ safe: Safe) {
        guard lastUpdatedAddress != safe.address else { return }
        isLoading = true
        Just(safe.address!)
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<SafeStatusRequest.Response, Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let safeInfo = try Safe.download(at: address)
                            promise(.success(safeInfo))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue: { response in
                self.lastUpdatedAddress = safe.address
                safe.update(from: response)
            })
            .store(in: &subscribers)
    }
    
}

extension LoadableSafeSettingsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let safe = controller.fetchedObjects?.first as? Safe else { return }
        if safe.address != lastUpdatedAddress {
            self.safe = safe
            updateOnce(safe)
        }
    }
}

extension Safe {
    func update(from safeInfo: SafeStatusRequest.Response) {
        threshold = Int32(safeInfo.threshold)
        owners = safeInfo.owners
        masterCopy = safeInfo.masterCopy
        version = safeInfo.version
        nonce = Int32(safeInfo.nonce)
        modules = safeInfo.modules
        fallbackHandler = safeInfo.fallbackHandler
    }
}
