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

    private let topPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 20
    let interItemSpacing: CGFloat = 12

    var body: some View {
        VStack(spacing: interItemSpacing) {
            BoldText("Please review our Terms of Use and Privacy Policy.")
                .multilineTextAlignment(.center)

            VStack(alignment: .leading) {
                BulletText("We do not collect demographic data such as age or gender.")
                BulletText("We collect anonymized app usage data and crash reports to ensure the quality of our app.")

                HStack {
                    LinkButton("Privacy Policy", url: App.shared.privacyPolicyURL)
                    LinkButton("Terms of Use", url: App.shared.termOfUseURL)
                }
            }

            Button("Agree") {
                AppSettings.acceptTerms()
                self.acceptedTerms = true
            }
            .buttonStyle(GNOFilledButtonStyle())

            Button("No Thanks") { self.isAgreeWithTermsPresented = false }
            .buttonStyle(GNOPlainButtonStyle())
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.horizontal)
    }

    struct BulletText: View {
        private let text: String
        private let bulletTopPadding: CGFloat = 8

        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            HStack(alignment: .top) {
                Image("ico-bullet-point")
                    .padding(.top, bulletTopPadding)
                Text(text)
                    .font(Font.gnoHeadline.weight(.medium))
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
