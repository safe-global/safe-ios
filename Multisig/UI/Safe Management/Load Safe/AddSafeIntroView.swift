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
        Button("Load Safe Multisig") {
            self.showsLoadSafe.toggle()
        }
        .buttonStyle(GNOFilledButtonStyle())
        .sheet(isPresented: self.$showsLoadSafe) {
            NavigationView {
                EnterSafeAddressView()
            }
            .environment(\.managedObjectContext, self.context)
        }
    }

}

struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        AddSafeIntroView()
    }
}
