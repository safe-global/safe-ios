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
    @Environment(\.displayScale)
    var displayScale: CGFloat

    var seed: String
    var size: Int = 8
    var scale: Int = 3

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: self.image(width: geometry.size.width))
                .clipShape(Circle())
        }
    }

    func image(width: CGFloat) -> UIImage {
        let pixelSize = Int(width * self.displayScale / CGFloat(self.scale))
        let image = Blockies(seed: self.seed,
                             size: self.size,
                             scale: pixelSize).createImage()
        return image!
    }

}

struct Identicon_Previews: PreviewProvider {
    static var previews: some View {
        EthIdenticon(seed: "Hello")
            .frame(width: 30, height: 30)
    }
}
