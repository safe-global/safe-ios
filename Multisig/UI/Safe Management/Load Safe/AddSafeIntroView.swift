//
//  AddSafeIntro.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeIntroView: View {
    var padding: (edge: Edge.Set, length: CGFloat) = (.all, 0)

    @State
    private var showsLoadSafe = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 21) {
                header
                loadSafeButton
            }
            .padding(.horizontal)
            .padding(padding.edge, padding.length)
        }
    }

    var backgroundView: some View {
        Rectangle()
            .foregroundColor(Color.gnoWhite)
            .edgesIgnoringSafeArea(.all)

    }

    var header: some View {
        Text("Get started by loading your\nSafe Multisig")
            .title()
            .multilineTextAlignment(.center)
    }

    var loadSafeButton: some View {
        NavigationLink(destination: EnterSafeAddressView(), isActive: $showsLoadSafe) {
            Text("Load Safe Multisig")
        }
        .buttonStyle(GNOFilledButtonStyle())
    }
}

struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        AddSafeIntroView()
    }
}
