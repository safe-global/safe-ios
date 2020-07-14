//
//  CollectiblesView.swift
//  Multisig
//
//  Created by Moaaz on 7/8/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectiblesView: Loadable {
    @ObservedObject
    var model: CollectiblesListViewModel

    init(safe: Safe) {
        self.model = CollectiblesListViewModel(safe: safe)
    }

    var body: some View {
        ZStack {
            if model.sections.isEmpty {
                EmptyListPlaceholder(label: "Collectibles will appear here", image: "ico-no-collectibles")
            } else {
                collectiblesList
            }
        }
        .onAppear {
            self.trackEvent(.assetsCollectibles)
        }
    }

    var collectiblesList: some View {
        List {
            ForEach(model.sections) { section in
                CollectiblesSectionView(section: section)
            }
        }
    }
}
