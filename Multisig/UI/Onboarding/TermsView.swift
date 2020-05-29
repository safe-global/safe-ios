//
//  TermsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 28.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TermsView: View {
    @Binding var acceptedTerms: Bool
    @Binding var isAgreeWithTermsPresented: Bool

    @State private var showPrivacyPolicy = false
    @State private var showTerms = false

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
                        self.showPrivacyPolicy = true
                    }) {
                        Text("Privacy Policy")
                            .underline()
                    }
                        .buttonStyle(GNOPlainButtonStyle())
                        .sheet(isPresented: $showPrivacyPolicy) {
                            SafariViewController(url: App.shared.privacyPolicyURL)
                        }

                    Button(action: {
                        self.showTerms = true
                    }) {
                        Text("Terms of Use")
                            .underline()
                    }
                        .buttonStyle(GNOPlainButtonStyle())
                        .sheet(isPresented: $showTerms) {
                            SafariViewController(url: App.shared.termOfUseURL)
                        }
                }
            }

            VStack(spacing: 12) {
                Button(action: {
                    AppSettings.acceptTerms()
                    self.acceptedTerms = true
                }) {
                    Text("Agree")
                }.buttonStyle(GNOFilledButtonStyle())

                Button(action: {
                    self.isAgreeWithTermsPresented = false
                }) {
                    Text("No Thanks")
                }.buttonStyle(GNOPlainButtonStyle())
            }

            Rectangle().frame(width: 0, height: 0)
        }
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom])
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView(acceptedTerms: .constant(false),
                  isAgreeWithTermsPresented: .constant(true))
    }
}
