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
    let imageURL: URL
    let size: CGFloat = 28

    var body: some View {
        KFImage(imageURL)
            .placeholder {
                Image("ico-token-placeholder")
            }
            .cancelOnDisappear(true)
            .resizable()
            .frame(width: size, height: size)
    }
}

struct EtherImage: View {
    let width: CGFloat = 24
    let height: CGFloat = 32

    var body: some View {
        Image("ico-ether")
            .frame(width: width, height: height)
    }
}
