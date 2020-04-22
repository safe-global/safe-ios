//
//  EnterSafeNameView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EnterSafeNameView: View {
    var address: String? = "0xAB3e244863e1a127333aBa15235aD50E0954146F"
    @State private var name: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Identicon(address!).frame(width: 40, height: 40, alignment: .center)
                HStack (alignment: .top) {
                    Image("ico-circle-check")
                    AddressText(address!).multilineTextAlignment(.center)
                }
                .padding(.trailing, 37)
                .padding(.top, 9)
                Text("Choose a name for the Safe. The name is only stored locally and will not be shared with Gnosis or any third parties.")
                    
                    .font(Font.gnoBody.weight(.medium))
                    .padding(.top, 27)
                    .padding(.bottom, 24)
                    .multilineTextAlignment(.center)

                VerifiableTextField(name: "Enter Name", validator: { input in
                    return input.isEmpty ? "Safe name can't be empty" : ""
                })
                
                
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
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Next")
            .fontWeight(.semibold)
        })
        .accentColor(.gnoHold)
    }
}

struct EnterSafeNameView_Previews: PreviewProvider {
    static var previews: some View {
        EnterSafeNameView(address: "0xAB3e244863e1a127333aBa15235aD50E0954146F")
    }
}
