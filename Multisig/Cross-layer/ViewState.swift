//
//  ViewState.swift
//  Multisig
//
//  Created by Moaaz on 5/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class ViewState: ObservableObject {

    static let shared = ViewState()
    
    @Published
    var state: ViewStateMode = .balanaces
    // Business Logic Layer
    
    private init() {
        
    }
}

enum ViewStateMode: Hashable {
    case balanaces
    case transactions
    case settings
}
