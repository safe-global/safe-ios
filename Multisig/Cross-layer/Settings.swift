//
//  Settings.swift
//  Multisig
//
//  Created by Moaaz on 10/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData
import Combine

class Settings: NSObject, ObservableObject {
    private let fetchResultsController: NSFetchedResultsController<AppSettings>

    @Published
    var signingKeyAddress: String?

    override init() {
        fetchResultsController = NSFetchedResultsController(fetchRequest: AppSettings.fetchRequest().all(),
                                                            managedObjectContext: App.shared.coreDataStack.viewContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        super.init()
        fetchResultsController.delegate = self
        try! fetchResultsController.performFetch()
        // after performFetch the delegate method 'controllerDidChangeContent' is not triggered,
        // so we need to trigger update here
        if let appSettings = fetchResultsController.fetchedObjects?.first {
           signingKeyAddress = appSettings.signingKeyAddress
        }
    }
}

extension Settings: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let appSettings = controller.fetchedObjects?.first as? AppSettings else { return }
        signingKeyAddress = appSettings.signingKeyAddress
    }
}
