//
//  ViewState.swift
//  Multisig
//
//  Created by Moaaz on 5/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

class ViewState: ObservableObject {

    @Published
    var state: ViewStateMode? = .balances

    @Published
    var hidesNavbar: Bool = true
    
}

enum ViewStateMode: Int, Hashable {
    case balances
    case transactions
    case settings
}
