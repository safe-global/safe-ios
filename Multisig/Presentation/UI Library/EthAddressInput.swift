//
//  AddressInput.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EthAddressInput: View {

    @State var address: EthAddress?
    @State var isError = false

    @State var showsActions = false

    var body: some View {
        HStack {
            // Note: SwiftUI does not support the 'if let'
            // statements inside stack's body (ViewBuilder)
            if address == nil {
                Text("Enter Safe address")
                        .padding()
                    .font(.gnoCallout)
            } else {
                EthIdenticon(address: address!)
                    .frame(width: 32, height: 32)
                    .padding()

                EthAddressText(address: address!)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .padding()
        }
        .foregroundColor(Color.gnoMediumGrey)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isError ? Color.gnoTomato : .gnoWhitesmoke,
                        lineWidth: 2)
        ).overlay(
            Button(action: {
                self.showsActions.toggle()
            }, label: {
                FullSize { Text("") }
            })
                .actionSheet(isPresented: self.$showsActions) {
                ActionSheet(title: Text("Select how to enter address"),
                            message: nil,
                            buttons: [
                    .default(Text("Paste From Clipboard")),
                    .default(Text("Scan QR Code")),
                    .default(Text("Enter ENS Name")),
                    .cancel()
                ])
            }
        )
    }
}

struct AddressInput_Previews: PreviewProvider {
    static var previews: some View {
        EthAddressInput(address: "0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826").padding()
    }
}
