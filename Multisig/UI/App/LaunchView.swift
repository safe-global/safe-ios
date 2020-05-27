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
    @Binding var updateToggle: Bool

    var body: some View {
        GeometryReader { gp in
            ZStack(alignment: .centerAlignment) {
                Rectangle()
                    .frame(width: 0, height: 0)
                    .alignmentGuide(.centerVerticalAlignment) { d in d[VerticalAlignment.center] }
                    .position(y: gp.size.height / 2)

                VStack(alignment: .center, spacing: 40) {
                    // 100 x 153 px
                    Image("launchscreen-logo")

                    // 282 × 89 px
                    Image("ico-splash-text")
                        .alignmentGuide(.centerVerticalAlignment) { d in
                            d[VerticalAlignment.center]
                        }

                    VStack(spacing: 20) {
                        Rectangle().frame(width: 0, height: 0)
                        Button("Get Started", action: {
                            AppSettings.acceptTerms()
                            self.updateToggle.toggle()                            
                        })
                            .buttonStyle(GNOFilledButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
          Group {
            LaunchView(updateToggle: .constant(false))
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE2")
            LaunchView(updateToggle: .constant(false))
                .previewDevice(PreviewDevice(rawValue: "iPhone XS Max"))
                .previewDisplayName("iPhone 11 Pro Max")
         }
    }
}
