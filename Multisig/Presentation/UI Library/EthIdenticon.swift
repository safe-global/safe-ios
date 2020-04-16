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

struct EthIdenticon: View {

    var address: EthAddress
    var blockSize: Int = 8

    var body: some View {

        GeometryReader { geometry in
            Image(uiImage:
                Blockies(seed: self.address.checksummed,
                         size: self.blockSize,
                         scale: Int(geometry.size.width / CGFloat(self.blockSize)))
                    .createImage()!
            ).clipShape(Circle())
        }
    }
}

struct Identicon_Previews: PreviewProvider {
    static var previews: some View {
        EthIdenticon(address: "Hello")
            .frame(width: 32, height: 32)
    }
}
