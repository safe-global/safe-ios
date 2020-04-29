//
//  SafeCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 27.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeCell: View {

    var safe: Safe?

    var body: some View {
        HStack {
            Identicon(safe?.address ?? "")
                .frame(width: 36, height: 36)
                .padding([.top, .leading, .bottom])
                .padding(.trailing, 4)

            VStack (alignment: .leading){
                BodyText(label: safe?.name ?? "")
                AddressText(safe?.address ?? "", style: .short)
                    .padding(.top, 4)
            }
        }
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
