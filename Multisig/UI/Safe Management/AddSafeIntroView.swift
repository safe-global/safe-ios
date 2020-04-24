//
//  AddSafeIntro.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeIntroView: View {
    @State private var addSafeStarted = false
    @State private var swithSafeDisplayed = false

    var body: some View {
        FullSize {
            Text("Get started by loading your\nSafe Multisig")
                .padding()
                .font(.gnoTitle3)
                .multilineTextAlignment(.center)
                .foregroundColor(.gnoDarkBlue)


            Button("Load Safe Multisig") {
                self.addSafeStarted = true
            }
            .buttonStyle(GNOFilledButtonStyle())
            .sheet(isPresented: self.$addSafeStarted) {
                EnterSafeAddressView()
            }

            Button("Switch Safe") {
                self.swithSafeDisplayed = true
            }
            .padding()
            .buttonStyle(GNOFilledButtonStyle())
            .sheet(isPresented: self.$swithSafeDisplayed) {
                SwitchSafeView()
                    .environment(\.managedObjectContext, CoreDataStack.shared.persistentContainer.viewContext)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.gnoWhite)
    }
}

#if DEBUG
struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        AddSafeIntroView()
    }
}
#endif
