//
//  Safe+Shared.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension Safe {
    var displayName: String { name.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled Safe" }
}

extension NSFetchRequest where ResultType == Safe {
    func by(address: String, chainId: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "address == %@ AND chain.id == %@", address, chainId)
        fetchLimit = 1
        return self
    }
}
