//
//  Currency.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import CoreData

extension ChainToken {
    @discardableResult
    static func create(name: String, symbol: String, decimals: Int) -> ChainToken {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let currency = ChainToken(context: context)
        currency.name = name
        currency.symbol = symbol
        currency.decimals = Int32(decimals)

        App.shared.coreDataStack.saveContext()
        
        return currency
    }
}

extension ChainToken {
    func update(name: String, symbol: String, decimals: Int) {
        self.name = name
        self.symbol = symbol
        self.decimals = Int32(decimals)
    }
}
