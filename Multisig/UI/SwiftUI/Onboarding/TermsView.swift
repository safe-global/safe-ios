//
//  TermsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 28.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TermsView: View {
    @Binding
    var acceptedTerms: Bool
    
    @Binding
    var isAgreeWithTermsPresented: Bool

    @State
    private var showPrivacyPolicy = false

    @State
    private var showTerms = false

    var onStart: () -> Void = { }

    private let topPadding: CGFloat = Spacing.extraLarge
    private let bottomPadding: CGFloat = Spacing.large
    let interItemSpacing: CGFloat = Spacing.small

    private let legal = App.configuration.legal

    var body: some View {
        VStack(spacing: interItemSpacing) {
            Text("Please review our Terms of Use and Privacy Policy.")
                .headline()
                .multilineTextAlignment(.center)

            VStack(alignment: .leading) {
                BulletText("We do not collect demographic data such as age or gender.")
                BulletText("We collect anonymized app usage data and crash reports to ensure the quality of our app.")

                HStack {
                    LinkButton("Privacy Policy", url: legal.privacyURL)
                    LinkButton("Terms of Use", url: legal.termsURL)
                }
            }

            Button("Agree") {
                AppSettings.termsAccepted = true 
                self.acceptedTerms = true
                self.onStart()
            }
            .buttonStyle(GNOFilledButtonStyle())

            Button("No Thanks") { self.isAgreeWithTermsPresented = false }
                .buttonStyle(GNOPlainButtonStyle())
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.horizontal)
        .background(Color.secondaryBackground)
    }

    struct BulletText: View {
        private let text: String
        private let bulletTopPadding: CGFloat = Spacing.extraSmall

        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            HStack(alignment: .top) {
                Image("ico-bullet-point")
                    .foregroundColor(.button)
                    .padding(.top, bulletTopPadding)
                Text(text)
                    .font(.gnoBody)
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
