//
//  Texts.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Font {
    // ordered by increasing font size, then weight
    static let gnoCaption3 =    system(size: 10, weight: .medium)
    static let gnoCaption2 =    system(size: 10, weight: .bold)

    static let gnoFootnote2 =   system(size: 13, weight: .medium)
    static let gnoCaption1 =    system(size: 13, weight: .bold)

    static let gnoSubhead =     system(size: 15, weight: .bold)

    static let gnoCallout =     system(size: 16)

    static let gnoBody =        system(size: 17, weight: .medium)
    static let gnoHeadline =    system(size: 17, weight: .semibold)
    static let gnoHeadline2 =   system(size: 17, weight: .bold)

    static let gnoTitle3 =      system(size: 20)

    static let gnoNormal =      custom("Averta Regular", size: 26)
}

// common text stylings
extension Text {
    func body(_ color: Color? = .labelPrimary) -> Self {
        font(.gnoBody).foregroundColor(color)
    }

    func footnote(_ color: Color? = .labelPrimary) -> Self {
        font(.gnoFootnote2).foregroundColor(color)
    }

    func headline(_ color: Color? = .labelPrimary) -> Self {
        font(.gnoHeadline).foregroundColor(color)
    }

    func title(_ color: Color? = .labelPrimary) -> Self {
        font(.gnoTitle3).foregroundColor(color)
    }

    func caption() -> Self {
        font(.gnoCaption1)
    }

    func error() -> some View {
        font(.gnoCallout)
            .foregroundColor(.error)
            .padding(.trailing)
            .padding(.top, 12)
    }
}
