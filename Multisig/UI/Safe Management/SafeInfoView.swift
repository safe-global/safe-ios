//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeInfo {
    var address: String
    var name: String
    var ensName: String

    var browseURL: URL {
         URL(string: "https://etherscan.io/address/\(address)")!
    }

    static let empty = SafeInfo(address: "", name: "", ensName: "")
}

struct SafeInfoView: View {

    var safeInfo: SafeInfo = .empty

    @State
    var showsBrowser: Bool = false
    
    var body: some View {
        VStack (alignment: .center, spacing: 18){
            Identicon(safeInfo.address)
                .frame(width: 56, height: 56)

            BodyText(label: safeInfo.name)

            addressView

            if !safeInfo.ensName.isEmpty {
                BodyText(label: safeInfo.ensName)
            }

            QRView(value: safeInfo.address)
                .frame(width: 150, height: 150)
        }
        .multilineTextAlignment(.center)
        .sheet(isPresented: $showsBrowser) {
            SafariViewController(url: self.safeInfo.browseURL)
        }
    }

    var addressView: some View {
        HStack {
            Button(action: {
                UIPasteboard.general.string = self.safeInfo.address
            }) {
                AddressText(safeInfo.address)
                    .multilineTextAlignment(.center)
            }

            Button(action: { self.showsBrowser.toggle() }) {
                Image("icon-external-link")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gnoHold)
            }
            .frame(width: 44, height: 44)

        }
            // these two lines make sure that the alignment will be by
            // the addreses text's center, and
            .padding([.leading, .trailing], 44)
            // that 'link button' will be visually attached to the trailnig
            .padding(.trailing, -44)
    }
    
}

struct SafeInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoView(safeInfo: SafeInfo(address: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
                                        name: "My Safe Name",
                                        ensName: "alice.eth"))
        .padding()
    }
}
