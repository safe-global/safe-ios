//
//  GNOTabItem.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct GNOTabItem<SelectionValue: Hashable>: Identifiable {
    var id: SelectionValue
    var label: AnyView
    var content: AnyView
}


