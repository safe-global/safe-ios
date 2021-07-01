//
//  NetworksListViewModel.swift
//  Multisig
//
//  Created by Moaaz on 7/1/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
struct NetworksListViewModel {
    var models: [SCGModels.Network] = []

    var isEmpty: Bool {
        models.isEmpty
    }

    var next: String?

    init(_ models: [SCGModels.Network] = []) {
        self.models = models
    }

    mutating func append(from list: Self) {
        self.next = list.next
        add(list.models)
    }

    mutating func add(_ models: [SCGModels.Network] = []) {
        self.models.append(contentsOf: models)
    }

    var lastTransaction: SCGModels.Network? {
        models.last
    }
}
