//
//  AddSafeIntro.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddSafeIntroView: View {
    @Binding var showsSafeInfo: Bool
    @Binding var showsSwitchSafe: Bool

    @State private var showsLoadSafe = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 21) {
                header
                loadSafeButton
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(leading: safeInfoButton, trailing: selectSafeButton)
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
        }
    }

    var safeInfoButton: some View {
        Button(action: { self.showsSafeInfo.toggle() }) {
            notSelectedView
                .padding(.bottom)
        }
    }

    var notSelectedView: some View {
        HStack {
            Image("safe-selector-not-selected-icon")
                .resizable()
                .renderingMode(.original)
                .frame(width: 30, height: 30)

            Text("No Safe loaded")
                .font(Font.gnoBody.weight(.semibold))
                .foregroundColor(Color.gnoMediumGrey)
        }
    }


    var selectSafeButton: some View {
        Button(action: { self.showsSwitchSafe.toggle() }) {
            Image(systemName: "chevron.down.circle")
                .foregroundColor(.gnoMediumGrey)
                .font(Font.body.weight(.semibold))
                // increases tappable area
                .frame(minWidth: 60, idealHeight: 44, alignment: .trailing)
        }

        .padding(.bottom)
    }
}

struct AddSafeIntro_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            NavigationView {
                AddSafeIntroView(showsSafeInfo: .constant(false),
                                 showsSwitchSafe: .constant(false))
            }
        }
    }
}
