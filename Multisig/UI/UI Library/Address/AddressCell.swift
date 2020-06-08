//
//  AddressCell.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressCell: View {

    enum Style {
        case shortAddress, normal, shortAddressNoShare, shortAddressNoShareGrayColor
    }

    let address: String
    var title: String = ""

    var style: Style = .normal

    @State
    private var showsLink: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Identicon(address).frame(width: 36, height: 36)
            
            CopyButton(address) {
                VStack (alignment: .leading) {
                    if !title.isEmpty {
                        BodyText(title)
                    }

                    addressText
                }
            }.disabled([.shortAddressNoShare, .shortAddressNoShareGrayColor].contains(style))

            if ![.shortAddressNoShare, .shortAddressNoShareGrayColor].contains(style) {
                Spacer()

                BrowseAddressView(address: address)
            }
        }
        .padding(EdgeInsets(top: 2, leading: 0, bottom: 6, trailing: 0))
    }

    var addressText: some View {
        var addressStyle: AddressText.Style = .long
        if style == .normal {
            addressStyle = .long
        }
        else if [.shortAddress, .shortAddressNoShareGrayColor].contains(style) {
            addressStyle = .short
        }
        else {
            addressStyle = .shortTrailColor
        }

        return AddressText(address, style: addressStyle)
                .font(Font.gnoBody.weight(.medium))
    }
    
    func browseSafeAddress() -> some View {
        return SafariViewController(url: Safe.browserURL(address: address))
    }
}

struct AddressCell_Previews: PreviewProvider {
    static var previews: some View {
        AddressCell(address: "0x71592E6Cbe7779D480C1D029e70904041F8f602A")
    }
}
