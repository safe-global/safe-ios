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

    // Navigation bar

    @Published
    var hidesNavbar: Bool = true

    // Snackbar

    @Published
    var showsSnackbar: Bool = false

    @Published
    var bottomBarHeight: CGFloat = 0

    @Published
    private(set) var snackbarMessge: String?

    private let messageHiding = PassthroughSubject<Void, Never>()
    private var subscribers = Set<AnyCancellable>()
    private let messageDuration: TimeInterval = 4

    init() {
        messageHiding
            .debounce(for: .seconds(messageDuration), scheduler: RunLoop.main)
            .sink {
                self.showsSnackbar = false
                self.snackbarMessge = nil
            }
            .store(in: &subscribers)
    }

    func show(message: String) {
        snackbarMessge = message
        showsSnackbar = true
        messageHiding.send()
    }

}

enum ViewStateMode: Int, Hashable {
    case balances
    case transactions
    case settings
}
