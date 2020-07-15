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

    private let imageDimention: CGFloat = 28
    var body: some View {
        VStack (alignment: .leading, spacing: 12) {
            HStack {
                TokenImage(width: imageDimention,
                           height: imageDimention,
                           url: section.imageURL,
                           name: "ico-nft-placeholder")
                Text(section.name).headline()
            }

            ForEach(section.collectibles) { collectible in
                CollectibleCellView(viewModel: collectible)
            }
        }.padding(.vertical)
    }
}
