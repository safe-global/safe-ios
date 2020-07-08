//
//  CollectiblesView.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectiblesView: View {
    var body: some View {
        ZStack {
            EmptyListPlaceholder(label: "Collectibles will appear here", image: "ico-no-collectibles")
        }
        .onAppear {
            self.trackEvent(.transactions)
        }
    }
}
