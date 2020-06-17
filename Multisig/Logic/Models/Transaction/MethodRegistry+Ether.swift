//
//  MethodRegistry+Ether.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension MethodRegistry {
    enum Ether {
        static func isValid(_ tx: Transaction) -> Bool {
            tx.data == nil && tx.operation == .call
        }
    }
}
