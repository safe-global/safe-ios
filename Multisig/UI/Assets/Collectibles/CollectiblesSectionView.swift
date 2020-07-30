//
//  CollectiblesSectionView.swift
//  Multisig
//
//  Created by Moaaz on 7/12/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectiblesSectionView: View {
    let section: CollectiblesListViewModel.Section

    private let imageDimension: CGFloat = Spacing.extraExtraLarge

    var body: some View {
        Section (header: header) {
            ForEach(section.collectibles) { collectible in
                NavigationLink(destination: CollectibleDetailsView(viewModel: collectible)) {
                    CollectibleCellView(viewModel: collectible)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    var header: some View {
        HStack {
            TokenImage(width: imageDimension, height: imageDimension, url: section.imageURL, name: "ico-nft-placeholder")
            Text(section.name).headline()
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color.white)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
