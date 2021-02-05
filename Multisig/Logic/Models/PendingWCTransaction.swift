//
//  PendingWCTransaction.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

extension PendingWCTransaction {

    static func create(wcSession: WCSession, nonce: UInt256String) {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext
        let pendingTransaction = PendingWCTransaction(context: context)
        pendingTransaction.session = wcSession
        pendingTransaction.nonce = nonce.description
        App.shared.coreDataStack.saveContext()
    }
    
}
