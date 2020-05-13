//
//  Icons.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Image {

    static let checkmark: some View =
        Image(systemName: "checkmark")
            .font(Font.body.weight(.semibold))
            .foregroundColor(.gnoHold)
            .frame(width: 24, height: 24)

    static let checkmarkCircle: some View =
        Image(systemName: "checkmark.circle")
            .font(Font.gnoBody.bold())
            .foregroundColor(Color.gnoHold)

    static let chevronDownCircle: some View =
        Image(systemName: "chevron.down.circle")
            .foregroundColor(.gnoMediumGrey)
            .font(Font.body.weight(.semibold))

    static let ellipsis = Image(systemName: "ellipsis")

    static let bigXMark: some View =
        Image(systemName: "xmark")
            .font(Font.gnoNormal)
            .foregroundColor(.gnoMediumGrey)
            .frame(width: 24, height: 24)

    static let plusCircle: some View =
        Image(systemName: "plus.circle")
            .font(Font.body.weight(.medium))
            .frame(width: 24, height: 24)


}
