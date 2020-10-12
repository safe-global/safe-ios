//
//  CollectibleBalancesView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectibleBalancesView: View {
    @EnvironmentObject var model: CollectibleBalancesModel
    var status: ViewLoadingStatus { model.status }

    var body: some View {
        NetworkContentView(status: model.status, reload: model.reload) {
            CollectibleListView(sections: model.result, reload: model.reload)
        }
        .onAppear {
            trackEvent(.assetsCollectibles)
        }
    }
}

struct CollectibleListView: View {
    var sections: [CollectibleListSection]
    var reload: () -> Void = {}

    var body: some View {
        if sections.isEmpty {
             EmptyListPlaceholder(label: "Collectibles will appear here",
                                  image: "ico-no-collectibles")
         } else {
            List {
                // For some reason, SwiftUI crashes after scrolling to top.
                // Wrapping into section fixed it.
                Section {
                    ReloadButton(reload: reload)
                }

                ForEach(sections) { section in
                    CollectiblesSectionView(section: section)
                }
           }
            .listStyle(GroupedListStyle())
         }
    }
}
