//
//  IdentifiableByHash.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//


struct IdentifiableByHash<T>: Identifiable where T: Hashable {

    var value: T

    init(_ value: T) {
        self.value = value
    }

    var id: Int { value.hashValue }

}
