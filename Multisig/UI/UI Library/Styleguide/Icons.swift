//
//  Icons.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Image {

    static let regularSize: CGFloat = 20

    // using static let ... = ... is crashing the app when the views are
    // deiniitialized, so instead we use the computed properties
    static var checkmark: some View {
        checkmark(size: regularSize)
    }

    static func checkmark(size: CGFloat) -> some View {
        icon("checkmark", size: size)
            .font(Font.body.weight(.semibold))
            .foregroundColor(.gnoHold)
    }

    static func icon(_ name: String, size: CGFloat) -> some View {
        Image(systemName: name)
            .resizable()
            .frame(width: size, height: size)
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
        icon("xmark", size: regularSize)
            .font(Font.gnoNormal)
            .foregroundColor(.gnoMediumGrey)
    }

    static var plusCircle: some View {
        icon("plus.circle", size: regularSize)
            .font(Font.body.weight(.medium))
    }

    static func exclamation(size: CGFloat) -> some View {
        icon("exclamationmark.circle", size: size)
            .foregroundColor(.gnoTomato)
            .font(Font.body.weight(.semibold))
    }

}
