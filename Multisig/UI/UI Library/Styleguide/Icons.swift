//
//  Icons.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Image {

    // using static let ... = ... is crashing the app when the views are
    // deiniitialized, so instead we use the computed properties
    static var checkmark: some View {
        Image(systemName: "checkmark")
            .font(Font.body.weight(.semibold))
            .foregroundColor(.gnoHold)
            .frame(width: 24, height: 24)
    }

    static var checkmarkCircle: some View {
        Image(systemName: "checkmark.circle")
            .font(Font.gnoBody.bold())
            .foregroundColor(Color.gnoHold)
    }

    static var chevronDownCircle: some View {
        Image(systemName: "chevron.down.circle")
            .resizable()
            .font(Font.body.weight(.medium))
            .foregroundColor(.gnoMediumGrey)
            .frame(width: 24, height: 24)
    }

    static var ellipsis: some View {
        Image(systemName: "ellipsis")
    }

    static var bigXMark: some View {
        Image(systemName: "xmark")
            .font(Font.gnoNormal)
            .foregroundColor(.gnoMediumGrey)
            .frame(width: 24, height: 24)
    }

    static var plusCircle: some View {
        Image(systemName: "plus.circle")
            .font(Font.body.weight(.medium))
            .frame(width: 24, height: 24)
    }

}
