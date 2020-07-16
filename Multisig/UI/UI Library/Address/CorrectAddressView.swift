//
//  CorrectAddressView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CorrectAddressView: View {

    var title: String?
    var address: String
    var checkmarkPosition = CheckmarkPosition.address

    var body: some View {
        VStack(spacing: 11) {
            if title != nil { titleView }

            Identicon(address).frame(width: 40, height: 40)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                checkmark(position: .address)

                SlicedText(address)
                    .style(.addressLong)
                    .font(Font.gnoBody.weight(.medium))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 27)
    }

    var titleView: some View {
        BodyText(title!)
            .background(
                checkmark(position: .title).offset(x: -25),
                alignment: .leading)
            .padding(.bottom)
    }

    func checkmark(position: CheckmarkPosition) -> some View {
        ZStack {
            if checkmarkPosition == position {
                Image.checkmarkCircle
            } else {
                EmptyView()
            }
        }
    }

    enum CheckmarkPosition {
        case address, title, none
    }
}

struct CorrectAddressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CorrectAddressView(
                title: "Address found",
                address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
                checkmarkPosition: .title)


            CorrectAddressView(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
        }
    }
}
