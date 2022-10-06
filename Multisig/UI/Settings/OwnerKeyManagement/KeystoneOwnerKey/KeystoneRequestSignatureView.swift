//
//  KeystoneRequestSignatureView.swift
//  Multisig
//
//  Created by Zhiying Fan on 3/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import URRegistry

struct KeystoneRequestSignatureView: View {
    let onTap: () -> Void
    
    @State private var qrValue = URRegistry.shared.nextPartUnsignedUR
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let qrViewSide: CGFloat = 300
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
            
            Group {
                Text("Scan this QR code with your Keystone wallet")
                    .headline()
                    .multilineTextAlignment(.center)
                
                QRView(value: qrValue, width: qrViewSide, height: qrViewSide)
                    .padding(.vertical, Spacing.extraLarge)
                    .onReceive(timer) { _ in
                        qrValue = URRegistry.shared.nextPartUnsignedUR
                    }
                
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
                onTap()
            }
            .buttonStyle(GNOFilledButtonStyle())
            .padding(.horizontal, Spacing.medium)
            .padding(.bottom, Spacing.extraSmall)
        }
    }
}

struct KeystoneRequestSignatureView_Previews: PreviewProvider {
    static var previews: some View {
        KeystoneRequestSignatureView(onTap: {})
    }
}
