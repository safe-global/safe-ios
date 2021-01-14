//
//  BrowseAddressView.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BrowseAddressView: View {
    @State
    private var showsLink: Bool = false
    
    let address: String
    
    var body: some View {
        Button(action: { self.showsLink.toggle()}) {
            Image("ico-browse-address").resizable()
        }
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.gnoHold)
        .frame(width: 24, height: 24)
        .sheet(isPresented: $showsLink, content: browseSafeAddress)
    }
    
    func browseSafeAddress() -> some View {
        return SafariViewController(url: Safe.browserURL(address: address))
    }
}

extension BrowseAddressView {
    init(address: Address) {
        self.address = address.checksummed
    }
}

struct BrowseAddressView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseAddressView(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
    }
}
