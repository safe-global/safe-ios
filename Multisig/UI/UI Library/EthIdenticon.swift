//
//  Identicon.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit
import BlockiesSwift

struct Identicon: View {

    var address: EthAddress
    private let blockSize: Int = 8

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage:
                Blockies(
                    seed: self.address.checksummed,
                    size: self.blockSize,
                    scale: Int(geometry.size.width / CGFloat(self.blockSize))
                ).createImage()!
            )
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
        }
    }
}

struct Identicon_Previews: PreviewProvider {
    static var previews: some View {
        Identicon(address: "Hello")
            .frame(width: 32, height: 32)
    }
}
