//
//  AddSafeIntro.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeIntro: View {
    var body: some View {
        VStack {

            Text("Get started by loading your\nSafe Multisig")
                .padding()
                .font(.gnoTitle3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gnoDarkBlue)

                Button("Load Safe Multisig") {
                    // open next screen
                }
                .buttonStyle(GNOFilledButtonStyle(width: 270))

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(Color.gnoWhite)
    }
}


struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        AddSafeIntro()
    }
}
