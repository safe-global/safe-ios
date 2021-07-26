//
//  KeyInfo+SharedFetchRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension NSFetchRequest where ResultType == KeyInfo {
    /// return keys with matching address
    func by(address: Address) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "addressString CONTAINS[c] %@", address.checksummed)
        fetchLimit = 1
        return self
    }
}
