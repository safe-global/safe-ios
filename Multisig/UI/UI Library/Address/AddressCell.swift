//
//  AddressCell.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AddressCell: View {
    let address: String
    
    @State
    private var showsLink: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Identicon(address).frame(width: 36, height: 36)
            
            Button(action: {
                UIPasteboard.general.string = self.address
            }) {
                AddressText(address)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            Button(action: { self.showsLink.toggle()}) {
                Image("icon-external-link").resizable()
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.gnoHold)
            .frame(width: 24, height: 24)
            .sheet(isPresented: $showsLink, content: browseSafeAddress)
        }.padding([.top, .bottom])
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
