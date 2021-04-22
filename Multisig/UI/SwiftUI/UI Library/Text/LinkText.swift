//
//  LinkText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct LinkText: View {

    var title: String

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(title).body(.button)
            Image("icon-external-link").foregroundColor(.button)
        }
    }
}

struct LinkText_Previews: PreviewProvider {
    static var previews: some View {
        LinkText(title: "some external link")
    }
}
