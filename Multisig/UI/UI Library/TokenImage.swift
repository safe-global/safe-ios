//
//  TokenImage.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 14.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import struct Kingfisher.KFImage

struct TokenImage: View {
    var imageURL: URL
    var size: CGFloat = 28

    var body: some View {
        KFImage(imageURL)
            .placeholder {
                Image(systemName: "arrow.2.circlepath.circle")
                    .font(.largeTitle)
                    .opacity(0.3)
            }
            .cancelOnDisappear(true)
            .resizable()
            .frame(width: size, height: size)
    }
}
