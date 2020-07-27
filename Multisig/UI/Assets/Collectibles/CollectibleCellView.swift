//
//  CollectibleCellView.swift
//  Multisig
//
//  Created by Moaaz on 7/9/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectibleCellView: View {
    let viewModel: CollectibleViewModel

    private let imageDimension: CGFloat = 144
    var body: some View {
        HStack (alignment: .top) {
            TokenImage(
                width: imageDimension,
                height: imageDimension,
                url: viewModel.imageURL,
                name: "ico-collectible-placeholder")

            VStack (alignment: .leading, spacing: 10) {
                Text(viewModel.name)
                    .headline(nameTextColor)

                Text(viewModel.description)
                    .body()
                    .lineLimit(3)
            }.padding(.vertical)

            Spacer()
        }
        .cornerRadius(10, antialiased: true)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color.gnoSnowwhite)
                .gnoShadow()
        )
    }

    private var nameTextColor: Color {
        viewModel.hasName ? .gnoDarkBlue : .gnoLightGrey
    }
}
