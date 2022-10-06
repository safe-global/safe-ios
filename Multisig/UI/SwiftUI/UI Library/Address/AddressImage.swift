//
//  AddressImage.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressImage: View {
    let address: Address?
    let blockSize: Int = 8

    @ViewBuilder var body: some View {
        if let address = address {
            GeometryReader { geometry in
                Image(
                    address: address,
                    size: self.blockSize,
                    scale: self.scale(for: geometry)
                )
                .renderingMode(.original)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .clipShape(Circle())
            }
        } else {
            Circle().foregroundColor(.backgroundSecondary)
        }
    }

    func scale(for geometry: GeometryProxy) -> Int {
        let block = blockSize == 0 ? 8 : abs(blockSize)
        return Int(min(geometry.size.width, geometry.size.height) / CGFloat(block))
    }
}

extension AddressImage {
    init(_ value: String?) {
        self.init(address: value.map { Address(exactly: $0) })
    }
}

struct AddressImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddressImage(address: "0x1230B3d59858296A31053C1b8562Ecf89A2f888b")
            AddressImage(address: nil)
        }
    }
}
