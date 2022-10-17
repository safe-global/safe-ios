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
        checkmark(size: 16)
    }

    static func checkmark(size: CGFloat) -> some View {
        icon("checkmark", size: size)
            .font(Font.body.weight(.semibold))
            .foregroundColor(.primary)
    }

    static func icon(_ name: String, size: CGFloat) -> some View {
        Image(systemName: name)
            .resizable()
            .frame(width: size, height: size)
    }

    static var checkmarkCircle: some View {
        Image(systemName: "checkmark.circle")
            .font(Font.body.weight(.medium))
            .foregroundColor(Color.primary)
    }

    static var chevronDownCircle: some View {
        Image(systemName: "chevron.down.circle")
            .resizable()
            .font(Font.body.weight(.medium))
            .foregroundColor(.labelSecondary)
            .frame(width: regularSize, height: regularSize)
    }

    static var chevronDown: some View {
        Image(systemName: "chevron.down")
            .resizable()
            .font(Font.body.weight(.medium))
            .foregroundColor(.labelSecondary)
            .frame(width: 12, height: 7)
    }

    static var chevronUp: some View {
        Image(systemName: "chevron.up")
            .resizable()
            .font(Font.body.weight(.medium))
            .foregroundColor(.labelSecondary)
            .frame(width: 12, height: 7)
    }

    static var ellipsis: some View {
        Image(systemName: "ellipsis")
    }

    static var bigXMark: some View {
        icon("xmark", size: regularSize)
            .foregroundColor(.labelTertiary)
    }

    static var plusCircle: some View {
        icon("plus.circle", size: regularSize)
            .font(Font.body.weight(.medium))
    }

    static func exclamation(size: CGFloat) -> some View {
        icon("exclamationmark.circle", size: size)
            .foregroundColor(.error)
            .font(Font.body.weight(.semibold))
    }

}
