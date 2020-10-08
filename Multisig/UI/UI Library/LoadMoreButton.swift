//
//  LoadMoreButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct LoadMoreButton: View {
    var loadMore: () -> Void = {}

    var body: some View {
        Button(action: loadMore, label: {
            HStack {
                Spacer()
                Text("Load more")
                Spacer()
            }
        })
        .frame(height: 44)
        .buttonStyle(GNOPlainButtonStyle())
    }
}
