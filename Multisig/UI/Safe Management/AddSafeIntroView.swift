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
    @State private var switcherShown = false

    var body: some View {
        FullSize {
            VStack(spacing: 21) {
                Text("Get started by loading your\nSafe Multisig")
                    .font(.gnoTitle3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gnoDarkBlue)


                Button("Load Safe Multisig") {
                    self.addSafeStarted.toggle()
                }
                .buttonStyle(GNOFilledButtonStyle())
                .sheet(isPresented: self.$addSafeStarted) {
                    NavigationView {
                        SafeAddressForm(form: SafeAddressFormModel())
                    }
                }

                Button("View Safes") {
                    self.switcherShown.toggle()
                }
                .buttonStyle(GNOFilledButtonStyle())
                .sheet(isPresented: self.$switcherShown) {
                    NavigationView {
                        // For some reason, the view doesn't get the
                        // context from the current environment of this view
                        SafeSwitcher()
                            .environment(\.managedObjectContext,
                                         CoreDataStack.shared.persistentContainer.viewContext)
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.gnoWhite)
    }
}


struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        AddSafeIntroView()
    }
}
