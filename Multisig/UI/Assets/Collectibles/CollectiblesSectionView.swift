//
//  CollectiblesSectionView.swift
//  Multisig
//
//  Created by Moaaz on 7/12/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectiblesSectionView: View {
    let section: CollectiblesViewModel.Section

    var body: some View {
        VStack (alignment: .leading, spacing: 12) {
            HStack {
                TokenImage(width: 28, height: 28, url: section.imageURL, name: "ico-nft-placeholder")
                BodyText(section.name).font(Font.gnoBody.weight(.semibold))
            }

            ForEach(section.collectibles) { collectible in
                CollectibleCellView(viewModel: collectible)
            }
        }.padding(.vertical)
    }
}
