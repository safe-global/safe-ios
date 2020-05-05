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
        HStack(spacing: 4) {
            Text(title)

            Image("icon-external-link")
        }
        .foregroundColor(.gnoHold)
    }
}

struct LinkText_Previews: PreviewProvider {
    static var previews: some View {
        LinkText(title: "some external link")
    }
}
