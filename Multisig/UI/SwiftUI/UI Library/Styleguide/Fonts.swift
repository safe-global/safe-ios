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
    static let subheadline =      custom("DMSans-Regular", size: 15)
    static let caption2 =      custom("DMSans-Bold", size: 12)

    static let callout =     custom("DMSans-Regular", size: 16)

    static let body =        custom("DMSans-Regular", size: 17)
    static let headline =    custom("DMSans-Medium", size: 17)
    static let button =   custom("DMSans-Medium", size: 17)

    static let title3 =      custom("DMSans-Medium", size: 20)
}

// common text stylings
extension Text {
    func body(_ color: Color? = .labelPrimary) -> Self {
        font(.body).foregroundColor(color)
    }

    func headline(_ color: Color? = .labelPrimary) -> Self {
        font(.headline).foregroundColor(color)
    }

    func error() -> some View {
        font(.callout)
            .foregroundColor(.error)
            .padding(.trailing)
            .padding(.top, 12)
    }
}
