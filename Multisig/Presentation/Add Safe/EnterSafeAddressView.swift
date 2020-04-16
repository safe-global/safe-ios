//
//  EnterSafeAddressView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterSafeAddressView: View {

    var address: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                Text("Enter your Safe Multisig address.")
                    .font(Font.gnoBody.weight(.medium))
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                EthAddressInput()

                text(
                    "Don't have a Safe? Create one first at",
                    link: "https://gnosis-safe.io"
                )
                .padding(.top, 18)

                Spacer()
            }
            .foregroundColor(.gnoDarkBlue)
            .padding()
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(leading: backButton, trailing: nextButton)
        }
    }

    var title: Text {
        Text("Load Safe Multisig")
            .font(Font.gnoBody.weight(.semibold))
            .foregroundColor(.gnoDarkBlue)
    }

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .accentColor(.gnoHold)
    }

    var nextButton: some View {
        NavigationLink(destination: EnterSafeNameView()) {
            Text("Next")
                .fontWeight(.semibold)
        }
        .accentColor(.gnoHold)
    }

    @State private var showsLink = false

    func text(_ text: String,
              link: String) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .foregroundColor(.gnoDarkBlue)

            Button(action: {
                self.showsLink = true
            }) {
                HStack(spacing: 4) {
                    Text(link)
                    Image("icon-external-link")
                }.foregroundColor(.gnoHold)
            }
        }
        .font(Font.gnoBody.weight(.medium))
        .sheet(isPresented: self.$showsLink) {
            SafariViewController(url: URL(string: link)!)
        }
    }
}

struct EnterSafeAddressView_Previews: PreviewProvider {
    static var previews: some View {
        EnterSafeAddressView()
    }
}
