//
//  CorrectAddressView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CorrectAddressView: View {

    var address: String

    var body: some View {
        VStack(spacing: 11) {
            Identicon(address).frame(width: 40, height: 40)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gnoHold)

                AddressText(address).multilineTextAlignment(.center)
            }
            .padding(.leading, -20)
        }
        .padding([.leading, .trailing], 27)
    }
}

struct CorrectAddressView_Previews: PreviewProvider {
    static var previews: some View {
        CorrectAddressView(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
    }
}
