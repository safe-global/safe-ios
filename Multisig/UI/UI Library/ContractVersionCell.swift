//
//  ContractVersionCell.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ContractVersionCell: View {
    
    var address: String
    var version: String

    var iconSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            Identicon(address)
                .frame(width: iconSize, height: iconSize)
    
            VStack(alignment: .leading, spacing: 2) {
                BoldText(version)
                AddressText(address, style: .short)
                    .font(Font.gnoBody.weight(.medium))
            }
            
            Spacer()
            
            BrowseAddressView(address: address)
        }
    }
}

struct ContractVersionCell_Previews: PreviewProvider {
    static var previews: some View {
        ContractVersionCell(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F", version: "1.0.0")
    }
}
