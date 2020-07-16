//
//  NonEmptyText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct NonEmptyText: View {
    let text: String

    @ViewBuilder var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            BodyText(text)
        }
    }
}

extension NonEmptyText {
    init(_ value: String) {
        self.init(text: value)
    }
}

struct NonEmptyText_Previews: PreviewProvider {
    static var previews: some View {
        NonEmptyText("Hello!")
    }
}
