//
//  ChainTheme.swift
//  Multisig
//
//  Created by Moaaz on 6/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

extension ChainTheme {
    @discardableResult
    static func create(textColor: String, backgroundColor: String) -> ChainTheme {
        dispatchPrecondition(condition: .onQueue(.main))
        let context = App.shared.coreDataStack.viewContext

        let theme = ChainTheme(context: context)
        theme.textColor = textColor
        theme.backgroundColor = backgroundColor

        App.shared.coreDataStack.saveContext()
        
        return theme
    }

    func update(textColor: String, backgroundColor: String) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
}
