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
    var width: CGFloat = 28
    var height: CGFloat = 28
    var url: URL?
    var name: String?

    static var ether: TokenImage {
        Self.init(width: 28, height: 32, name: "ico-ether")
    }

    static var placeholder: TokenImage {
        self.init(name: "ico-token-placeholder")
    }

    var body: some View {
        ZStack {
            if url != nil {
                KFImage(url!)
                    .placeholder {
                        Image(name ?? "ico-token-placeholder")
                }
                .cancelOnDisappear(true)
                .resizable()
                .frame(width: width, height: height)
            } else {
                Image(name ?? "ico-token-placeholder")
                    .frame(width: width, height: height)
            }
        }
    }
}
