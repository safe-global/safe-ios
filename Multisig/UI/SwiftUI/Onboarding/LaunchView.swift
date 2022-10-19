//
//  LaunchView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension HorizontalAlignment {
    private enum CenterHorizontalAlignment : AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            return d[HorizontalAlignment.center]
        }
    }

    static let centerHorizontalAlignment = HorizontalAlignment(CenterHorizontalAlignment.self)
}

extension VerticalAlignment {
    private enum CenterVerticalAlignment : AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            return d[VerticalAlignment.center]
        }
    }

    static let centerVerticalAlignment = VerticalAlignment(CenterVerticalAlignment.self)
}

extension Alignment {
    static let centerAlignment = Alignment(horizontal: .centerHorizontalAlignment, vertical: .centerVerticalAlignment)
}

struct LaunchView: View {
    @Binding
    var acceptedTerms: Bool

    @State
    var showTerms = false

    var onStart: () -> Void = {}

    private let logoToTextSpacing: CGFloat = 40
    private let textToButtonSpacing: CGFloat = 60

    var body: some View {
        GeometryReader { geometryProxy in

            ZStack(alignment: .centerAlignment) {
                VStack(alignment: .center, spacing: 0) {
                    // 100 x 153 px, so no additional framing is required
                    Image("launchscreen-logo")
                        .padding(.bottom,  self.logoToTextSpacing)

                    // 282 × 89 px, so no additional framing is required
                    Image("ico-splash-text")
                        .alignmentGuide(.centerVerticalAlignment) { $0[VerticalAlignment.center] }
                        .padding(.bottom, self.textToButtonSpacing)
                }

                Button("Get Started") {
                    self.showTerms = true
                    // overlay view is loaded immediately
                    // so we can not track on view appear
                    Tracker.trackEvent(.launchTerms)
                }
                .buttonStyle(GNOFilledGreenButtonStyle())
                .position(x: geometryProxy.size.width / 2 - 16, y: geometryProxy.size.height - 72)

            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
        .overlay(BottomOverlayView(isPresented: $showTerms) {
            TermsView(acceptedTerms: $acceptedTerms,
                      isAgreeWithTermsPresented: $showTerms,
                      onStart: onStart)
        })
        .preferredColorScheme(.dark)
        .background(Color.backgroundPrimary)

        .edgesIgnoringSafeArea(.all)
        .onAppear {
            Tracker.trackEvent(.launch)
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LaunchView(acceptedTerms: .constant(false), showTerms: true)
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE2")
            LaunchView(acceptedTerms: .constant(false), showTerms: true)
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
                .previewDisplayName("iPhone 11 Pro Max")
        }
    }
}
