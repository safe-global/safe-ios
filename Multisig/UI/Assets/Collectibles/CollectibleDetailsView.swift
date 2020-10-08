//
//  CollectibleDetailsView.swift
//  Multisig
//
//  Created by Moaaz on 7/14/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CollectibleDetailsView: View {
    @ObservedObject
    var theme: Theme = App.shared.theme

    let viewModel: CollectibleViewModel

    private let cornerRadius: CGFloat = 10
    
    var body: some View {
        List {
            VStack (alignment: .leading, spacing: 7) {
                TokenImage(width: nil, height: nil, url: viewModel.imageURL, name: "ico-collectible-placeholder")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fill)
                    .cornerRadius(cornerRadius)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .foregroundColor(Color.gnoSnowwhite)
                            .gnoShadow()
                    )
                
                Text(viewModel.name).body()

                if viewModel.tokenID != nil {
                    Text(viewModel.tokenID!).footnote()
                }

                Text(viewModel.description).body()
            }

            AddressCell(address: viewModel.address, title: "Asset Contract", style: .shortAddress)

            if viewModel.website != nil && viewModel.websiteName != nil {
                BrowseLinkButton(title: "View on " + viewModel.websiteName!, url: viewModel.website!)
            }
        }
        .padding()
        .onAppear {
            self.trackEvent(.assetsCollectiblesDetails)
        }
        .navigationBarTitle("Collectible Details", displayMode: .inline)
    }
}
