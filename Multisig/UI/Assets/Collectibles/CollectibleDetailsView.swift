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

    private let imageDimention: CGFloat = 100
    
    var body: some View {
        List {
            VStack (alignment: .leading, spacing: 7) {
                TokenImage(width: nil, height: nil, url: viewModel.imageURL, name: "ico-collectible-placeholder")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fill)
                    .cornerRadius(10, antialiased: true)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.white)
                            .gnoShadow()
                    )
                
                BodyText(viewModel.name)

                if viewModel.tokenID != nil {
                    FootnoteText(viewModel.tokenID!)
                }

                BodyText(viewModel.description)
            }

            AddressCell(address: viewModel.address, title: "Asset Contract", style: .shortAddress)

            if viewModel.website != nil && viewModel.websiteName != nil {
                BrowseLinkButton(title: "View on " + viewModel.websiteName!, url: viewModel.website!)
            }

        }.padding()

        .onAppear {
            self.theme.setTemporaryTableViewBackground(nil)
            self.trackEvent(.assetsCollectiblesDetails)
        }
        .onDisappear {
            self.theme.resetTemporaryTableViewBackground()
        }
        .navigationBarTitle("Collectible Details", displayMode: .inline)
    }
}
