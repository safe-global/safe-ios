//
//  QRView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRView: View {

    var value: String!
    
    var width: CGFloat = 124
    var height: CGFloat = 124
    
    var body: some View {
        VStack {
            if value != nil && !value!.isEmpty {
                Image(uiImage: UIImage.generateQRCode(value: value))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle().foregroundColor(Color.backgroundTetriary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Color.labelTetriary, lineWidth: 2)
        )
        .frame(width: width, height: height)
    }
}

struct QRView_Previews: PreviewProvider {
    static var previews: some View {
        QRView(value: "0xAB3e244863e1a127333aBa15235aD50E0954146F")
    }
}
