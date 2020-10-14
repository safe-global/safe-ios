//
//  ViewState.swift
//  Multisig
//
//  Created by Moaaz on 5/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

class ViewState: ObservableObject {
    @Published
    private(set) var state: ViewStateMode = .balances

    func switchTab(_ to: ViewStateMode) {
        state = to
    }

    @Published
    var showsSafesList = false

    @Published
    var showImportKeySheet = false

    @Published
    var hidesNavbar = true
}

enum ViewStateMode: Int, Hashable {
    case balances
    case transactions
    case settings
}
