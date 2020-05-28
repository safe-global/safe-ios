//
//  TermsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 28.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TermsView: View {

    var body: some View {
        VStack(spacing: 12) {
            BoldText("Please review our Terms of Use and Privacy Policy.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image("ico-bullet-point")
                        .padding(.top, 8)
                    Text("We do not collect demographic data such as age or gender.")
                        .font(Font.gnoHeadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .top) {
                    Image("ico-bullet-point")
                        .padding(.top, 8)
                    Text("We collect anonymized app usage data and crash reports to ensure the quality of our app.")
                        .font(Font.gnoHeadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Button(action: {
                        print("Privacy Policy")
                    }) {
                        Text("Privacy Policy")
                            .underline()
                    }.buttonStyle(GNOPlainButtonStyle())

                    Button(action: {
                        print("Terms of Use")
                    }) {
                        Text("Terms of Use")
                            .underline()
                    }.buttonStyle(GNOPlainButtonStyle())
                }
            }

            VStack(spacing: 12) {
                Button(action: {
                    print("Agree")
                }) {
                    Text("Agree")
                }.buttonStyle(GNOFilledButtonStyle())

                Button(action: {
                    print("No Thanks")
                }) {
                    Text("No Thanks")
                }.buttonStyle(GNOPlainButtonStyle())
            }
        }
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom])
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
    }
}
