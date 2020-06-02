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
                BulletText(text: "We do not collect demographic data such as age or gender.")
                BulletText(
                    text: "We collect anonymized app usage data and crash reports to ensure the quality of our app.")

                HStack {
                    LinkButton(name: "Privacy Policy", url: App.shared.privacyPolicyURL)
                    LinkButton(name: "Terms of Use", url: App.shared.termOfUseURL)
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

    struct BulletText: View {
        let text: String
        let bulletTopPadding: CGFloat = 8

        var body: some View {
            HStack(alignment: .top) {
                Image("ico-bullet-point")
                    .padding(.top, bulletTopPadding)
                Text(text)
                    .font(Font.gnoHeadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView(acceptedTerms: .constant(false),
                  isAgreeWithTermsPresented: .constant(true))
    }
}
