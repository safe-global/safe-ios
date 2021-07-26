//
//  Chain+SharedFetchRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension NSFetchRequest where ResultType == Chain {
    func by(id: String) -> Self {
        sortDescriptors = []
        predicate = NSPredicate(format: "id == %@", id)
        fetchLimit = 1
        return self
    }
}
