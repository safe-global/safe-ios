//
//  AddressInput.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressInput: View {
    var body: some View {
        HStack {
            Text("Enter Safe address")
                .padding()
                .font(.gnoCallout)

            Spacer()

            Image(systemName: "ellipsis")
                .padding()
        }
        .foregroundColor(Color.gnoMediumGrey)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gnoWhitesmoke, lineWidth: 2)
        )
    }
}

struct AddressInput_Previews: PreviewProvider {
    static var previews: some View {
        AddressInput().padding()
    }
}
