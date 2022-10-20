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

    var onStart: () -> Void

    private let topPadding: CGFloat = Spacing.extraLarge
    private let bottomPadding: CGFloat = Spacing.large
    let interItemSpacing: CGFloat = Spacing.small

    private let legal = App.configuration.legal

    var body: some View {
        VStack(spacing: interItemSpacing) {
            Text("Our Terms of Use and Privacy Policy")
                .headline()
                .multilineTextAlignment(.center)

            VStack(alignment: .leading) {
                BulletText("We collect anonymized app usage data and crash reports to ensure the quality of our app.")
                BulletText("We do not collect demographic data such as age or gender.")
                HStack (spacing: 0) {
                    BulletText("Read more in")
                    LinkButton("Privacy Policy", url: legal.privacyURL).padding(0)
                    Text("and").body(.labelSecondary)
                    LinkButton("Terms of Use", url: legal.termsURL).padding(0)
                }
            }

            Button("Get Started") {
                agreeWithTerms()
                AppSettings.trackingEnabled = true
            }
            .buttonStyle(GNOFilledButtonStyle()).preferredColorScheme(.dark)

            Button("Accept without sharing data") {
                agreeWithTerms()
                AppSettings.trackingEnabled = false
            }
            .padding(.bottom)
            .buttonStyle(GNOPlainButtonStyle())
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.horizontal)
        .background(Color.backgroundSecondary)
        .preferredColorScheme(.light)
        
    }

    private func agreeWithTerms() {
        AppSettings.termsAccepted = true
        self.acceptedTerms = true
        self.onStart()
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
                    .foregroundColor(.labelSecondary)
                    .padding(.top, bulletTopPadding)
                Text(text)
                    .body(.labelSecondary)
            }
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView(acceptedTerms: .constant(false),
                  isAgreeWithTermsPresented: .constant(true), onStart: {})
    }
}
