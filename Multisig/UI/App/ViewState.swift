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

    // Active tab

    @Published
    private(set) var state: ViewStateMode? = .balances

    func switchTab(_ to: ViewStateMode?) {
        state = to
    }

    @Published
    var presentedSafeTxHash: String?

    // Navigation bar

    @Published
    var hidesNavbar: Bool = true

}    

enum ViewStateMode: Int, Hashable {
    case balances
    case transactions
    case settings
}
