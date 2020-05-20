//
//  AddSafeIntro.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeIntroView: View {
    @Environment(\.managedObjectContext) var context: CoreDataContext
    @State private var showsLoadSafe = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 21) {
                header
                loadSafeButton
            }
            .padding(.horizontal)
        }
    }

    var backgroundView: some View {
        Rectangle()
            .foregroundColor(Color.gnoWhite)
            .edgesIgnoringSafeArea(.all)

    }

    var header: some View {
        Text("Get started by loading your\nSafe Multisig")
            .font(.gnoTitle3)
            .multilineTextAlignment(.center)
            .foregroundColor(.gnoDarkBlue)
    }

    var loadSafeButton: some View {
        NavigationLink(destination: EnterSafeAddressView()) {
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
