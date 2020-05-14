//
//  SafeCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 27.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeCell: View {

    @ObservedObject
    var safe: Safe

    var style: Style = .regular

    var body: some View {
        HStack(spacing: style.iconToTextSpacing) {
            Identicon(safe.address ?? "")
                .frame(width: style.iconSize, height: style.iconSize)

            VStack(alignment: .leading) {
                BoldText(safe.name ?? "")
                    .padding(.bottom, style.nameToAddressPadding)
                    .lineLimit(1)

                AddressText(safe.address ?? "", style: .short)
                    .font(Font.gnoBody.weight(.medium))
            }
        }
    }

    struct Style {
        var iconSize: CGFloat
        var iconToTextSpacing: CGFloat
        var nameToAddressPadding: CGFloat

        static let compact = Style(
            iconSize: 34,
            iconToTextSpacing: 6,
            nameToAddressPadding: -5)

        static let regular = Style(
            iconSize: 36,
            iconToTextSpacing: 12,
            nameToAddressPadding: 0)
    }

}

struct SafeCell_Previews: PreviewProvider {

    static var safe: Safe {
        let s = Safe()
        s.name = "My Safe"
        s.address = "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F"
        return s
    }

    static var previews: some View {
        SafeCell(safe: safe)
    }
}
