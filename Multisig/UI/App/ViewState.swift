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
    private(set) var state: ViewStateMode? = .balances

    func switchTab(_ to: ViewStateMode?) {
        state = to
    }

    @Published
    var hidesNavbar: Bool = true

    @Published
    var showsSnackbar: Bool = false

    @Published
    var bottomBarHeight: CGFloat = 0

    @Published
    private(set) var snackbarMessge: String?

    func toggle(message: String) {
        if snackbarMessge == nil || message != snackbarMessge {
            snackbarMessge = message
            showsSnackbar = true
        } else {
            snackbarMessge = nil
            showsSnackbar = false
        }
    }

}

enum ViewStateMode: Int, Hashable {
    case balances
    case transactions
    case settings
}
