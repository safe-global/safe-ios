//
//  KeystoneRequestSignatureView.swift
//  Multisig
//
//  Created by Zhiying Fan on 3/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct KeystoneRequestSignatureView: View {
    private let qrViewSide: CGFloat = 237
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
            
            Group {
                Text("Scan this QR code with your Keystone wallet")
                    .headline()
                    .multilineTextAlignment(.center)
                
                QRView(value: "0xb09f0eB9bebA0F7be33F1B56396246AA17405584", width: qrViewSide, height: qrViewSide)
                    .padding(.vertical, Spacing.extraLarge)
                
                Group {
                    Text("Sign the transaction with your wallet, then click on ")
                        .body(.labelSecondary) +
                    Text("Get signature. ")
                        .headline()
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.extraExtraExtraLarge)
            
            Spacer()
            
            Button("Get signature") {
                print("Get signature Tapped")
            }
            .buttonStyle(GNOFilledButtonStyle())
            .padding(.horizontal, Spacing.medium)
            .padding(.bottom, Spacing.extraSmall)
        }
    }
}

struct KeystoneRequestSignatureView_Previews: PreviewProvider {
    static var previews: some View {
        KeystoneRequestSignatureView()
    }
}
