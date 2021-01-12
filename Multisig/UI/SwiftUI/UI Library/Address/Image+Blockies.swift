//
//  Image+Blockies.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit
import BlockiesSwift

extension Image {
    init(blocky seed: String? = nil,
          size: Int = 8,
          scale: Int = 4,
          customScale: Int = 1,
          color: UIColor? = nil,
          bgColor: UIColor? = nil,
          spotColor: UIColor? = nil) {
        let uiImage = Blockies(seed: seed,
                               size: size,
                               scale: scale,
                               color: color,
                               bgColor: bgColor,
                               spotColor: spotColor)
            .createImage(customScale: customScale)
        if let image = uiImage {
            self.init(uiImage: image)
        } else {
            self.init("ico-token-placeholder")
        }
    }

    init(address: Address?,
          size: Int = 8,
          scale: Int = 4,
          customScale: Int = 1,
          color: UIColor? = nil,
          bgColor: UIColor? = nil,
          spotColor: UIColor? = nil) {
        self.init(blocky: address?.hexadecimal,
                  size: size,
                  scale: scale,
                  customScale: customScale,
                  color: color,
                  bgColor: bgColor,
                  spotColor: spotColor)
    }
}

struct Image_Blockies_Previews: PreviewProvider {
    static let addresses: [Address] = [
        "0x0000000000000000000000000000000000000000",
        "0x2333b4CC1F89a0B4C43e9e733123C124aAE977EE",
        "0x1230B3d59858296A31053C1b8562Ecf89A2f888b",
    ]

    static var previews: some View {
        ForEach(addresses, id: \.self) { item in
            Image(address: item)
                .previewLayout(.sizeThatFits)
                .previewDisplayName(item.checksummed)
        }
    }
}
